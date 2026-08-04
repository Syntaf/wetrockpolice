import { Controller } from "@hotwired/stimulus";
import precipResponse from '../fixtures/precipitation_response';
import { SYNOPTIC_OK_CODE } from "../constants";
import { parseDailyIntervals, parseHourlyIntervals } from "../utils";
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

const apiOptions = {
  'token': '2153743de639465ebbb30fa392c748de',
  'stid': '',
  'recent': 28800,
  'units': 'english',
  'interval': 'hour',
  'precip': 1,
}

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
    const intervals = await this.fetchPrecipitationIntervals();

    this.renderRainInformation(intervals);
    this.renderRainGraph(intervals);
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

  renderRainInformation(intervals) {
    const lastRainInterval = this.findLastRainInterval(intervals);

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
