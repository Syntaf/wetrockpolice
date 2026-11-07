import { Controller } from "@hotwired/stimulus";
import { Tooltip as BootstrapTooltip } from "bootstrap";
import { SYNOPTIC_OK_CODE } from "../constants";
import { findModelRainAfter, parseDailyIntervals, parseHourlyIntervals } from "../utils";
// Named imports instead of 'chart.js/auto' so esbuild tree-shakes every
// controller/scale/plugin the bar chart doesn't use. Registered below:
// type 'bar' needs BarController + BarElement, its default category x-axis
// needs CategoryScale, the numeric y-axis needs LinearScale, and the
// default-enabled legend + hover tooltips need their plugins.
import {
  Chart,
  BarController,
  BarElement,
  CategoryScale,
  LinearScale,
  Tooltip,
  Legend
} from 'chart.js';
import { format } from 'date-fns';

Chart.register(BarController, BarElement, CategoryScale, LinearScale, Tooltip, Legend);

// Spots around each gauge to check with Open-Meteo's modeled rain, to catch
// showers that miss the gauge (#87). When the model has rain more recent than
// the gauge's, the time-since-rain tiles use it. Free, keyless, non-commercial
// use, CC BY 4.0 (credit shown whenever it's used).
const MODEL_POINTS = {
  'RRKN2': [
    { name: 'Calico Basin', lat: 36.153, lng: -115.427 },
    { name: 'Pine Creek', lat: 36.108, lng: -115.484 },
    { name: 'Black Velvet', lat: 36.038, lng: -115.465 },
  ],
};
const MODEL_PAST_DAYS = 3;
// The hour-by-hour median of these is what counts. Open-Meteo's default model
// alone (HRRR-led in the US) showed 0mm at Red Rock for the 2026-10-30
// overnight storm that ECMWF, ICON and GEM each put at 10-15mm.
const MODEL_NAMES = ['ncep_hrrr_conus', 'ecmwf_ifs025', 'icon_seamless', 'gem_seamless'];
// mm in an hour before modeled rain counts; the model reports tiny amounts
// that never wet the rock
const MODEL_MIN_MM = 0.25;
const MODEL_TIMEOUT_MS = 5000;

export default class extends Controller {
  static targets = [
    "rainTileSection",
    "rainGraphSection",
    "loading",
    "daysTile",
    "daysLabel",
    "hoursTile",
    "hoursLabel",
    "lastRainDate",
    "gaugeName",
    "nextGaugeName",
    "infoBubble",
    "graphToggle"
  ]

  static values = {
    'precipitationUrl': String,
    'station': String,
    // [{ slug, name, label, station, url, excerpt }], primary gauge first. Only
    // areas with alternate gauges get the hero switch button.
    'gauges': Array,
    'gaugeIndex': Number,
    'developmentMode': Boolean
  }

  connect() {
    // Server-side manual_warn styling has to survive a gauge switch; the
    // model-rain warning (added per load) must not.
    this.serverManualWarn = this.daysTileTarget.classList.contains('manual-warn');
    this.loadId = 0;

    this.restoreSavedGauge();
    this.saveGauge();
    this.loadRainData();
  }

  disconnect() {
    this.timeSeriesChart?.destroy();
    this.timeSeriesChart = null;
  }

  // Hero switch button: move to the next gauge and reload everything below it.
  switchGauge(event) {
    event?.preventDefault();
    if (this.gaugesValue.length < 2) return;

    this.showGauge((this.gaugeIndexValue + 1) % this.gaugesValue.length);
    this.saveGauge();
    this.resetRainDisplay();
    this.loadRainData();
  }

  // Returning visitors open on the gauge they last looked at. An explicit
  // ?gauge= link wins (the server already picked it), and nothing has loaded
  // yet, so there's no reset or reload, just the title and URL to update.
  restoreSavedGauge() {
    if (this.gaugesValue.length < 2) return;
    if (new URL(window.location.href).searchParams.has('gauge')) return;

    const slug = this.readStorage(this.gaugeStorageKey);
    if (!slug) return;

    const index = this.gaugesValue.findIndex(gauge => gauge.slug === slug);
    if (index > 0 && index !== this.gaugeIndexValue) this.showGauge(index);
  }

  // The primary gauge is the default, so it clears the key, not stores ''.
  saveGauge() {
    if (this.gaugesValue.length < 2) return;

    const slug = this.gaugesValue[this.gaugeIndexValue]?.slug;
    try {
      if (slug) {
        window.localStorage.setItem(this.gaugeStorageKey, slug);
      } else {
        window.localStorage.removeItem(this.gaugeStorageKey);
      }
    } catch {
      // Private mode or blocked storage: the switch still works, it just isn't remembered.
    }
  }

  readStorage(key) {
    try {
      return window.localStorage.getItem(key);
    } catch {
      return null;
    }
  }

  // One preference per area. The primary gauge's proxy path is the area's
  // own (/redrock/precipitation), so it keys the area without a new value.
  get gaugeStorageKey() {
    return `rain-gauge:${this.gaugesValue[0]?.url}`;
  }

  // Point the title, callout, tooltip, URL and fetch target at gauges[index].
  showGauge(index) {
    const gauge = this.gaugesValue[index];
    const next = this.gaugesValue[(index + 1) % this.gaugesValue.length];

    this.gaugeIndexValue = index;
    this.precipitationUrlValue = gauge.url;
    this.stationValue = gauge.station;

    if (this.hasGaugeNameTarget) this.gaugeNameTarget.textContent = gauge.name;
    if (this.hasNextGaugeNameTarget) this.nextGaugeNameTarget.textContent = next.label;
    this.updateInfoBubble(gauge.excerpt);
    this.updateGaugeQueryParam(gauge.slug);
  }

  updateInfoBubble(text) {
    if (!this.hasInfoBubbleTarget || !text) return;

    this.infoBubbleTarget.setAttribute('title', text);
    BootstrapTooltip.getInstance(this.infoBubbleTarget)?.setContent({ '.tooltip-inner': text });
  }

  // Keep the URL shareable: /redrock?gauge=black-velvet opens on that gauge.
  updateGaugeQueryParam(slug) {
    const url = new URL(window.location.href);
    if (slug) {
      url.searchParams.set('gauge', slug);
    } else {
      url.searchParams.delete('gauge');
    }
    window.history.replaceState(window.history.state, '', url);
  }

  // Back to the just-loaded state: spinners up, tiles and chart cleared.
  resetRainDisplay() {
    this.loadingTargets.forEach(el => { el.style.display = ''; });

    [this.daysTileTarget, this.hoursTileTarget].forEach(tile => {
      tile.innerHTML = '';
      if (!this.serverManualWarn) tile.classList.remove('manual-warn');
    });
    this.daysLabelTarget.innerHTML = 'Days';
    this.hoursLabelTarget.innerHTML = 'Hours';
    this.lastRainDateTarget.innerHTML = '';

    // The model-rain note is inserted as "<br><small>"; take both out.
    const note = this.element.querySelector('[data-role="model-rain-note"]');
    if (note) {
      if (note.previousElementSibling?.tagName === 'BR') note.previousElementSibling.remove();
      note.remove();
    }
    const excerpt = this.element.querySelector('[data-role="excerpt"]');
    if (excerpt && !this.serverManualWarn) excerpt.classList.remove('manual-warn');

    if (this.hasGraphToggleTarget) this.graphToggleTarget.checked = false;
    this.timeSeriesChart?.destroy();
    this.timeSeriesChart = null;
  }

  hideLoading() {
    this.loadingTargets.forEach(el => { el.style.display = 'none'; });
  }

  async loadRainData() {
    // A click mid-load starts a newer load; the older one must not render.
    const loadId = ++this.loadId;
    const isStale = () => loadId !== this.loadId;

    let intervals = null;

    // Never rejects (it returns null on any failure), so a slow or broken
    // Open-Meteo can only delay the page by MODEL_TIMEOUT_MS, never break it.
    const forecastsPromise = this.fetchModelForecasts();

    try {
      intervals = await this.fetchPrecipitationIntervals();
    } catch (error) {
      // A rejected fetch (network down), a non-JSON body (ingress error
      // page), an unexpected shape -- whatever went wrong, the page must
      // degrade to a message, never hang on the spinners.
      console.error('Failed to fetch precipitation data', error);
    }

    if (isStale()) return;

    if (intervals === null) {
      this.renderWeatherUnavailable();
      return;
    }

    const modelRain = this.findMissedModelRain(intervals, await forecastsPromise);
    if (isStale()) return;

    this.renderRainInformation(intervals, modelRain);
    this.renderRainGraph(intervals);
  }

  // Open-Meteo's modeled hourly rain at this area's points, or null (no points
  // configured, or the request failed or was slow: the gauge still works)
  async fetchModelForecasts() {
    const points = MODEL_POINTS[this.stationValue];
    if (!points) return null;

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), MODEL_TIMEOUT_MS);

    try {
      const fetchParams = new URLSearchParams({
        latitude: points.map(p => p.lat).join(','),
        longitude: points.map(p => p.lng).join(','),
        hourly: 'precipitation',
        models: MODEL_NAMES.join(','),
        past_days: MODEL_PAST_DAYS,
        forecast_days: 1,
        timezone: 'GMT',
      });
      const response = await fetch(
        'https://api.open-meteo.com/v1/forecast?' + fetchParams.toString(),
        { signal: controller.signal }
      );
      if (!response.ok) return null;

      const data = await response.json();
      return Array.isArray(data) ? data : [data];
    } catch (error) {
      console.error('Could not fetch modeled rain', error);
      return null;
    } finally {
      clearTimeout(timer);
    }
  }

  // Modeled rain newer than anything the gauge recorded, if any
  findMissedModelRain(intervals, forecasts) {
    const points = MODEL_POINTS[this.stationValue];
    if (!points || !forecasts) return null;

    const gaugeRain = this.findLastRainInterval(intervals);
    const gaugeLastRain = gaugeRain ? new Date(gaugeRain.interval.last_report) : null;

    return findModelRainAfter(forecasts, points, MODEL_NAMES, gaugeLastRain, new Date(), MODEL_MIN_MM);
  }

  async fetchPrecipitationIntervals() {
      const data = await this.fetchObservations();

      // The Rails proxy reports its own failures as { "error": ... }:
      // 502 when Synoptic is down, 503 when the token or station is not
      // configured. All of them land in the same degraded rendering.
      if (data['error']) {
        console.error('Precipitation proxy returned an error', data['error']);
        return null;
      }

      if (!data['SUMMARY']) {
        console.error('Received malformed response', data);
        return null;
      }

      if (data['SUMMARY']['RESPONSE_CODE'] !== SYNOPTIC_OK_CODE) {
        const code = data['SUMMARY']['RESPONSE_CODE'];
        const msg = data['SUMMARY']['RESPONSE_MESSAGE'];

        console.error('Bad response fetching precipitation data', code, msg);
        return null;
      }

      const observations = data['STATION'][0]['OBSERVATIONS'];

      const intervalData = observations['precip_intervals_set_1d'];
      const intervalDates = observations['date_time'];

      return intervalData.reduce((intervals, interval, idx) => [
          ...intervals,
          {
            'precip': interval,
            'last_report': intervalDates[idx]
          }
        ], []);
  }

  async fetchObservations() {
    if (this.developmentModeValue) {
      // Dynamic import so esbuild splits the 123KB mock Synoptic response
      // into a separate chunk that is only ever fetched in development —
      // a static top-level import would ship it to every production visitor.
      const { default: precipResponse } =
        await import('../fixtures/precipitation_response');

      return new Promise((resolve) => {
        setTimeout(() => {
          resolve(precipResponse);
        }, 1500);
      });
    }

    // Rails proxies the Synoptic request server-side (Area::WeatherController)
    // so the API token never ships to the browser. The proxy passes the
    // upstream JSON through unchanged, so the parsing above is untouched.
    const response = await fetch(this.precipitationUrlValue);

    return await response.json();
  }

  // Terminal state for every failure path: clear the spinners, put
  // something honest in the tiles, and skip the chart entirely.
  renderWeatherUnavailable() {
    this.hideLoading();
    this.daysTileTarget.innerHTML = '?';
    this.hoursTileTarget.innerHTML = '?';

    this.lastRainDateTarget.innerHTML =
      'Weather data is temporarily unavailable — please check back shortly.';
  }

  renderRainInformation(intervals, modelRain = null) {
    const gaugeRain = this.findLastRainInterval(intervals);
    // the model only comes back when it's newer than the gauge's last rain
    const lastRainInterval = modelRain
      ? {
          elapsedHours: (new Date() - modelRain.at) / (1000 * 60 * 60),
          interval: { last_report: modelRain.at.toISOString() }
        }
      : gaugeRain;

    if (!lastRainInterval) {
        this.hideLoading();
        this.daysTileTarget.innerHTML = '&#8734;';
        this.hoursTileTarget.innerHTML = '&#8734;' ;

        this.lastRainDateTarget.innerHTML =
          'Nothing to look at down here, come back when weather is looking bleak.';

        return;
    }

    const elapsedHours = lastRainInterval.elapsedHours;
    const days = Math.floor(elapsedHours / 24);
    const hours = Math.floor(elapsedHours % 24);

    this.hideLoading();
    this.daysTileTarget.innerHTML = days;
    this.hoursTileTarget.innerHTML = hours;

    if (days === 1) {
      this.daysLabelTarget.innerHTML = 'Day';
    }

    if (hours === 1) {
      this.hoursLabelTarget.innerHTML = 'Hour';
    }

    // Label just below hero image, saying the date it last rained
    const dateOfRain = new Date(lastRainInterval.interval.last_report);

    const month = this.getMonth(dateOfRain.getMonth());
    const day = this.getOrdinalSuffix(dateOfRain.getDate());

    this.lastRainDateTarget.innerHTML = `${month} ${day}`;

    if (modelRain) this.showModelRainSource(modelRain);
  }

  // Say where the time came from, since the gauge didn't record this rain
  showModelRainSource(modelRain) {
    this.daysTileTarget.classList.add('manual-warn');
    this.hoursTileTarget.classList.add('manual-warn');

    const excerpt = this.element.querySelector('[data-role="excerpt"]');
    if (!excerpt) return;

    // An area with manual_warn already has the class (and its own warning),
    // but the note and credit still go in: CC BY wants the credit wherever
    // the model's numbers show.
    excerpt.classList.add('manual-warn');
    if (excerpt.querySelector('[data-role="model-rain-note"]')) return;

    excerpt.insertAdjacentHTML('beforeend',
      `<br><small data-role="model-rain-note">Rain modeled at ${modelRain.name}, which the rain gauge didn't record. ` +
      '<a href="https://open-meteo.com/" target="_blank" rel="noopener">Weather data by Open-Meteo.com</a></small>');
  }

  findLastRainInterval(intervals) {
    const latestRainInterval = 
      intervals.toReversed().find(interval => interval.precip > 0);

    if (!latestRainInterval) return null;

    const now = new Date();
    const periodEnd = new Date(latestRainInterval['last_report']);
    const diffInMilliseconds = now - periodEnd;
    const elapsedHours = diffInMilliseconds / (1000 * 60 * 60);

    return {
      elapsedHours,
      interval: latestRainInterval
    };
  }

  getMonth(monthIndex) {
      const months = [
          "January", "February", "March", "April", "May", "June",
          "July", "August", "September", "October", "November", "December"
      ];

      return months[monthIndex];
  }

  getOrdinalSuffix(i) {
    const j = i % 10,
          k = i % 100;

    if (j == 1 && k != 11) {
        return i + "st";
    }

    if (j == 2 && k != 12) {
        return i + "nd";
    }

    if (j == 3 && k != 13) {
        return i + "rd";
    }

    return i + "th";
  }

  renderRainGraph(intervals) {
    this.timeSeriesDailyData = parseDailyIntervals(intervals);
    this.timeSeriesHourlyData = parseHourlyIntervals(intervals);

    const timeSeriesCanvas = document.getElementById("timeSeries").getContext('2d');
    this.timeSeriesChart = new Chart(timeSeriesCanvas, {
        type: 'bar',
        data: {
            labels: this.timeSeriesDailyData.map(intv => format(intv.label, "LLL do")),
            datasets: [{
                label: 'Accumulated Precipitation (rolling 24 hours)',
                data: this.timeSeriesDailyData.map(intv => intv.value),
                barThickness: 30,
                backgroundColor: 'rgba(255, 99, 132, 0.5)',
                borderColor: 'rgb(255, 99, 132, 0.7)',
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            aspectRatio: false,
            showTooltips: true,
            scales: {
              y: {
                ticks: {
                  beginAtZero: true,
                  callback: (v) => `${v.toFixed(2)} in`
                },
              }
            }
        }
    });
  }

  toggleGraphDisplay(event) {
    // No chart exists when the weather data failed to load.
    if (!this.timeSeriesChart) return;

    const checked = event.target.checked;

    if (checked) {
      this.timeSeriesChart.config.data.datasets[0].data =
        this.timeSeriesHourlyData.map(intv => intv.value);
      this.timeSeriesChart.config.data.labels =
        this.timeSeriesHourlyData.map(intv => format(intv.label, 'LLL do haaa'));
    } else {
      this.timeSeriesChart.config.data.datasets[0].data =
        this.timeSeriesDailyData.map(intv => intv.value);
      this.timeSeriesChart.config.data.labels =
        this.timeSeriesDailyData.map(intv => format(intv.label, 'LLL do'));
    }

    this.timeSeriesChart.update();
  }
}
