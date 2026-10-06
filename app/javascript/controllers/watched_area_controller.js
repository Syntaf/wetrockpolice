import { Controller } from "@hotwired/stimulus";
import precipResponse from '../fixtures/precipitation_response';
import { SYNOPTIC_OK_CODE } from "../constants";
import { findModelRainAfter, parseDailyIntervals, parseHourlyIntervals } from "../utils";
import Chart from 'chart.js/auto';
import { format } from 'date-fns';

const apiOptions = {
  'token': '2153743de639465ebbb30fa392c748de',
  'stid': '',
  'recent': 28800,
  'units': 'english',
  'interval': 'hour',
  'precip': 1,
}

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
    "lastRainDate"
  ]

  static values = {
    'station': String,
    'developmentMode': Boolean
  }

  async connect() {
    const [intervals, forecasts] = await Promise.all([
      this.fetchPrecipitationIntervals(),
      this.fetchModelForecasts(),
    ]);
    const modelRain = this.findMissedModelRain(intervals, forecasts);

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

    return findModelRainAfter(forecasts, points, gaugeLastRain, new Date(), MODEL_MIN_MM);
  }

  async fetchPrecipitationIntervals() {
      const data = await this.fetchObservations();

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
      return new Promise((resolve) => {
        setTimeout(() => {
          resolve(precipResponse);
        }, 1500);
      });
    }

    const fetchParams = new URLSearchParams({
      ...apiOptions,
      'stid': this.stationValue
    });

    const response = await fetch(
      'https://api.synopticdata.com/v2/stations/timeseries?' + fetchParams.toString()
    );

    return await response.json();

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
        this.loadingTargets.forEach(el => el.remove());
        this.daysTileTarget.innerHTML = '&#8734;';
        this.hoursTileTarget.innerHTML = '&#8734;' ;
        
        this.lastRainDateTarget.innerHTML =
          'Nothing to look at down here, come back when weather is looking bleak.';

        return;
    }

    const elapsedHours = lastRainInterval.elapsedHours;
    const days = Math.floor(elapsedHours / 24);
    const hours = Math.floor(elapsedHours % 24);

    this.loadingTargets.forEach(el => el.remove());
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
    if (!excerpt || excerpt.classList.contains('manual-warn')) return;

    excerpt.classList.add('manual-warn');
    excerpt.insertAdjacentHTML('beforeend',
      `<br><small>Rain modeled at ${modelRain.name}, which the rain gauge didn't record. ` +
      '<a href="https://open-meteo.com/" target="_blank" rel="noopener">Weather data by Open-Meteo.com</a></small>');
  }

  findLastRainInterval(intervals) {
    if (!intervals) return null;

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
    const dailyIntervalLabel = (tooltipItems, data) => 
        ` ${data.labels[tooltipItems.index].format('ll')} - ${tooltipItems.yLabel.toFixedDown(3)} inches of rain`;
    const hourlyIntervalLabel = (tooltipItems, data) =>
        ` ${data.labels[tooltipItems.index].format('lll')} - ${tooltipItems.yLabel.toFixedDown(3)} inches of rain`;

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

// function LandingController(apiOptions) {
//     this.apiOptions = $.extend({
//         'token': '2153743de639465ebbb30fa392c748de',
//         'stid': '',
//         'recent': 28800,
//         'units': 'english',
//         'interval': 'hour',
//         'precip': 1,
//     }, apiOptions);
// }