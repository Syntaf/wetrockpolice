import { Controller } from "@hotwired/stimulus";
import { Tooltip as BootstrapTooltip } from "bootstrap";
import { SYNOPTIC_OK_CODE } from "../constants";
import {
  HOURLY_LOOKBACK_DAYS,
  findModelRainAfter,
  parseDailyIntervals,
  parseHourlyIntervals
} from "../utils";
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
import { addDays, format, startOfDay } from 'date-fns';
import { minBandWidth, rainWindowsPlugin } from '../rain_chart_plugin';

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

const HOUR_MS = 60 * 60 * 1000;
// Climbers should wait 24 to 72 hours after rain. Until 72 hours have
// passed, the title says how many and a warning shows under it.
const RECENT_RAIN_HOURS = 72;
// The fewest days the daily chart narrows to: the shaded 72 hours plus today
// can touch four.
const MIN_DAILY_DAYS = 4;
const DAYS_PER_WEEK = 7;

// The x-axis labels for a series: for each bar, null or its lines, each
// { text }. With more than a week of dates, the month shows once a week,
// counting from the first, and wherever a new month starts; the rest are
// just the day: "Sep 1", "2", ... "7", "Sep 8". The hourly chart adds the
// weekday ("Fri") underneath.
const axisLabels = (series, mode) => {
  const dated = series.flatMap((intv, i) => (mode.labelled(intv.label) ? [i] : []));
  const weekly = dated.length > DAYS_PER_WEEK;
  const labels = series.map(() => null);

  dated.forEach((index, k) => {
    const date = series[index].label;
    const previous = k > 0 ? series[dated[k - 1]].label : null;
    const newMonth = previous !== null && previous.getMonth() !== date.getMonth();
    const withMonth = !weekly || k % DAYS_PER_WEEK === 0 || newMonth;

    labels[index] = [{ text: format(date, withMonth ? 'LLL d' : 'd') }];
    if (mode.weekday) labels[index].push({ text: format(date, 'EEE') });
  });
  return labels;
};
const SHADING_NOTE = ' Shading marks the last 24, 48 and 72 hours.';

// What the Daily/Hourly switch changes on the chart. `labelled` says which
// bars get an x-axis date (see axisLabels for the rest of the axis options);
// `tooltipFormat` is the hover label. `slot` is the
// time a bar covers, [startMs, endMs], which places the 24/48/72-hour shading;
// `gridLine` says whether a gridline goes on the boundary before a bar.
const GRAPH_MODES = {
  daily: {
    legend: 'Rain per day (inches)',
    description: 'Each bar is the total rain for one calendar day, midnight ' +
      'to midnight in your time zone. The last bar is today so far.' + SHADING_NOTE,
    tooltipFormat: 'LLL do',
    // A date under every bar, centred, slanting when they're tight
    labelled: () => true,
    weekday: false,
    labelAtBoundary: false,
    maxRotation: 50,
    // startOfDay/addDays, not +24h, so a daylight-saving day is 23 or 25 hours
    slot: (date) => [startOfDay(date).getTime(), addDays(startOfDay(date), 1).getTime()],
    gridLine: () => true,
    backgroundColor: 'rgb(255, 99, 132)',
    borderWidth: 0,
    categoryPercentage: 0.8,
    barPercentage: 0.9
  },
  hourly: {
    legend: 'Rain per hour (inches)',
    description: 'Each bar is the rain recorded in one hour, over the last ' +
      `${HOURLY_LOOKBACK_DAYS} days.` + SHADING_NOTE,
    tooltipFormat: 'LLL do haaa',
    // One date and one gridline per day, on its first hour, instead of one
    // per bar. The date and weekday start at the gridline, level.
    labelled: (date) => date.getHours() === 0,
    weekday: true,
    labelAtBoundary: true,
    maxRotation: 0,
    // Each reading is the rain in the hour up to its timestamp
    slot: (date) => [date.getTime() - HOUR_MS, date.getTime()],
    gridLine: (date) => date.getHours() === 0,
    // Bars are a pixel or two wide on a phone: borderless, since a border
    // would swallow them. Solid, like the daily bars.
    backgroundColor: 'rgb(255, 99, 132)',
    borderWidth: 0,
    categoryPercentage: 1,
    barPercentage: 0.8
  }
};

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
    "graphToggle",
    "graphDescription",
    "rainHeader",
    "rainWarning"
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
    this.defaultRainHeader = this.hasRainHeaderTarget ? this.rainHeaderTarget.textContent : null;
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
    this.showRecentRain(null);

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

    this.latestReading = intervals.length
      ? new Date(intervals[intervals.length - 1].last_report)
      : null;

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

    return findModelRainAfter(forecasts, points, MODEL_NAMES, gaugeLastRain, this.currentTime(), MODEL_MIN_MM);
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
          elapsedHours: (this.currentTime() - modelRain.at) / (1000 * 60 * 60),
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
    this.showRecentRain(elapsedHours);

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

  // Under 72 hours since rain: "The last recorded precipitation was 30 hours
  // ago on" and the warning. Otherwise (or null) the title as the page has it.
  showRecentRain(elapsedHours) {
    const recent = elapsedHours !== null && elapsedHours < RECENT_RAIN_HOURS;

    if (this.hasRainHeaderTarget && this.defaultRainHeader !== null) {
      if (recent) {
        // Bold, like the date after it
        const hours = document.createElement('strong');
        hours.dataset.role = 'rain-hours-ago';
        hours.textContent = this.hoursAgo(elapsedHours);
        this.rainHeaderTarget.replaceChildren(
          'The last recorded precipitation was ', hours, ' on');
      } else {
        this.rainHeaderTarget.textContent = this.defaultRainHeader;
      }
    }
    if (this.hasRainWarningTarget) this.rainWarningTarget.hidden = !recent;
  }

  hoursAgo(elapsedHours) {
    const hours = Math.floor(elapsedHours);
    if (hours < 1) return 'less than an hour ago';
    return hours === 1 ? '1 hour ago' : `${hours} hours ago`;
  }

  findLastRainInterval(intervals) {
    const latestRainInterval = 
      intervals.toReversed().find(interval => interval.precip > 0);

    if (!latestRainInterval) return null;

    const now = this.currentTime();
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
            labels: [],
            datasets: [{
                data: [],
                // No fixed barThickness: Chart.js fits bars to the space each
                // one has, so they never overlap on a narrow screen. The cap
                // keeps the few daily bars from turning into slabs on desktop.
                maxBarThickness: 30,
                borderColor: 'rgb(255, 99, 132, 0.7)'
            }]
        },
        options: {
            responsive: true,
            aspectRatio: false,
            showTooltips: true,
            // A narrower or wider window can change how many days fit
            onResize: (chart, size) => {
              if (!this.graphHourly && this.chartGutter !== undefined) {
                this.fitDailyDays(size.width - this.chartGutter);
              }
            },
            scales: {
              x: {
                // rainWindowsPlugin draws the vertical gridlines, always
                // between bars (see its comment for why not Chart.js's own)
                grid: { display: false },
                // Invisible: rainWindowsPlugin draws the labels (see
                // applyGraphMode)
                ticks: { color: 'transparent' }
              },
              y: {
                beginAtZero: true,
                // Headroom: the tallest bar stops at 80% of the height or
                // less, clear of the shading labels along the top. (Chart.js
                // takes a grace percentage of half the range: 50% adds 25%.)
                grace: '50%',
                grid: { display: false },
                ticks: {
                  callback: (v) => `${v.toFixed(2)} in`
                },
              }
            }
        },
        plugins: [rainWindowsPlugin]
    });

    // A new chart (first load or a gauge switch) has shown no days yet
    this.dailyDaysShown = null;
    this.chartGutter = undefined;
    this.showGraphMode(false);
  }

  toggleGraphDisplay(event) {
    // No chart exists when the weather data failed to load.
    if (!this.timeSeriesChart) return;

    this.showGraphMode(event.target.checked);
  }

  showGraphMode(hourly) {
    this.graphHourly = hourly;

    if (hourly) {
      this.applyGraphMode(GRAPH_MODES.hourly, this.timeSeriesHourlyData);
    } else {
      this.fitDailyDays();
    }
  }

  // The most recent days that each get room for a "72h" label (all of them
  // on a desktop; fewer on a phone) instead of squeezing every day in.
  fitDailyDays(plotWidth = this.plotWidth()) {
    const chart = this.timeSeriesChart;
    const all = this.timeSeriesDailyData;
    const minWidth = minBandWidth(chart.ctx);
    const fits = (width) =>
      Math.min(all.length, Math.max(MIN_DAILY_DAYS, Math.floor(width / minWidth)));

    let days = fits(plotWidth);
    if (days === this.dailyDaysShown) return;

    this.applyGraphMode(GRAPH_MODES.daily, all.slice(-days));

    // The axes may take a few more pixels once the real labels are in
    while (days > MIN_DAILY_DAYS && fits(chart.chartArea.width) < days) {
      days -= 1;
      this.applyGraphMode(GRAPH_MODES.daily, all.slice(-days));
    }
  }

  plotWidth() {
    const chart = this.timeSeriesChart;
    return chart.chartArea ? chart.chartArea.width : chart.width;
  }

  // Point the chart, its legend and the description under it at one series.
  applyGraphMode(mode, series) {
    const chart = this.timeSeriesChart;
    const hourly = mode === GRAPH_MODES.hourly;
    const dataset = chart.data.datasets[0];

    // Labels are what the tooltip shows; the axis ticks are set separately.
    chart.data.labels = series.map(intv => format(intv.label, mode.tooltipFormat));
    dataset.data = series.map(intv => intv.value);
    dataset.label = mode.legend;
    dataset.backgroundColor = mode.backgroundColor;
    dataset.borderWidth = mode.borderWidth;
    dataset.categoryPercentage = mode.categoryPercentage;
    dataset.barPercentage = mode.barPercentage;

    const ticks = chart.options.scales.x.ticks;
    const labels = axisLabels(series, mode);
    // Every label shows, so the weekly months above stay put: daily days are
    // kept wide enough (fitDailyDays), and hourly labels only one bar a day.
    ticks.autoSkip = false;
    ticks.maxRotation = mode.maxRotation;
    // Chart.js makes room for the labels from this text, drawn invisibly;
    // rainWindowsPlugin draws them where they belong (see its afterDraw).
    ticks.callback = (value) => {
      const lines = labels[value]?.map(line => line.text);
      if (!lines) return null;
      return lines.length === 1 ? lines[0] : lines;
    };
    chart.$axisLabels = { labels, atBoundary: mode.labelAtBoundary };

    chart.$rainWindows = {
      anchor: this.currentTime(),
      slots: series.map(intv => mode.slot(intv.label)),
      gridIndices: series
        .map((intv, i) => (mode.gridLine(intv.label) ? i : null))
        .filter(i => i !== null)
        // and the right-hand edge, after the last bar
        .concat(mode === GRAPH_MODES.daily ? [series.length] : [])
    };

    if (this.hasGraphDescriptionTarget) {
      this.graphDescriptionTarget.textContent = mode.description;
    }

    chart.update();

    this.dailyDaysShown = hourly ? null : series.length;
    // Everything but the plot area (mostly the y-axis), to size it on resize
    this.chartGutter = chart.width - chart.chartArea.width;
  }

  // The time the tiles, the title and the chart's shading count back from.
  // The development fixture is a snapshot from September 2024, so there "now"
  // is its latest reading: the page then looks as it did that evening,
  // instead of two years without rain.
  currentTime() {
    return this.developmentModeValue && this.latestReading ? this.latestReading : new Date();
  }
}
