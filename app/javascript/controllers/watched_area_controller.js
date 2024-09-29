import { Controller } from "@hotwired/stimulus";
import precipResponse from '../fixtures/precipitation_response';
import { SYNOPTIC_OK_CODE } from "../constants";
import { parseDailyIntervals, parseHourlyIntervals } from "../utils";
import Chart from 'chart.js/auto';
import { format } from 'date-fns';


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
  ];

  static apiOptions = {
    'token': '2153743de639465ebbb30fa392c748de',
    'stid': '',
    'recent': 28800,
    'units': 'english',
    'interval': 'hour',
    'precip': 1,
  }

  async connect() {
    const intervals = await this.fetchPrecipitationIntervals();

    this.renderRainInformation(intervals);
    this.renderRainGraph(intervals);
  }

  // TODO -- make the actual API request
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
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve(precipResponse);
      }, 1500);
    });
  }

  renderRainInformation(intervals) {
    const lastRainInterval = this.findLastRainInterval(intervals);

    if (!lastRainInterval) {
        this.loadingTargets.forEach(el => el.remove());
        this.daysTileTarget.innerHTML = '&#8734;';
        this.hoursTileTarget.innerHTML = '&#8734;' ;
        
        this.lastRaindateTarget.innerHTML =
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
    const dailyIntervalLabel = (tooltipItems, data) => 
        ` ${data.labels[tooltipItems.index].format('ll')} - ${tooltipItems.yLabel.toFixedDown(3)} inches of rain`;
    const hourlyIntervalLabel = (tooltipItems, data) =>
        ` ${data.labels[tooltipItems.index].format('lll')} - ${tooltipItems.yLabel.toFixedDown(3)} inches of rain`;

    const timeSeriesDailyData = parseDailyIntervals(intervals);
    const timeSeriesHourlyData = parseHourlyIntervals(intervals);

    const timeSeriesCanvas = document.getElementById("timeSeries").getContext('2d');
    const timeSeriesChart = new Chart(timeSeriesCanvas, {
        type: 'bar',
        data: {
            labels: timeSeriesDailyData.map(intv => format(intv.label, "LLL do")),
            datasets: [{
                label: 'Accumulated Precipitation (rolling 24 hours)',
                data: timeSeriesDailyData.map(intv => intv.value),
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

    $('#graphSwitch').change(function() {
        if ($(this).prop('checked')) {
            timeSeriesChart.config.data.datasets[0].data = timeSeriesHourlyData.data;
            timeSeriesChart.config.data.labels = timeSeriesHourlyData.labels;
            timeSeriesChart.config.options.scales.xAxes[0].time.unit = 'hour';
            timeSeriesChart.config.options.tooltips.callbacks.label = hourlyIntervalLabel;
            timeSeriesChart.update();
        } else {
            timeSeriesChart.config.data.datasets[0].data = timeSeriesDailyData.data;
            timeSeriesChart.config.data.labels = timeSeriesDailyData.labels
            timeSeriesChart.config.options.scales.xAxes[0].time.unit = 'day';
            timeSeriesChart.config.options.tooltips.callbacks.label = dailyIntervalLabel;
            timeSeriesChart.update();
        }
    });
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

// LandingController.prototype.initLandingView = function () {
//     $('button[data-role="scroll-to-weather"]').click(this.scrollToWeather.bind(this));

//     this.fetchPrecipitation()
//         .then(this.renderView.bind(this));
// }

// LandingController.prototype.initSnowAnimation = function () {
//     particlesJS.load('particles-js', '/snow.json', $.noop)
// }

// LandingController.prototype.scrollToWeather = function () {
//     var $weatherSection = $('[data-role="weather-section"]');
//     var offsetToScrollTo = $weatherSection.offset().top;

//     $('html, body').animate({
//         'scrollTop': offsetToScrollTo
//     }, 700);
// }

// LandingController.prototype.fetchPrecipitation = function () {
//     return $.ajax({
//         'method': 'GET',
//         'url': 'https://api.synopticdata.com/v2/stations/timeseries',
//         'data': this.apiOptions,
//         'dataType': 'json'
//     });
// }

// LandingController.prototype.renderView = function (synopticResponse) {
//     if (synopticResponse.SUMMARY.RESPONSE_CODE !== 1) {
//         console.error(
//             'Fetching precipitation data failed with response code: \'' +
//             synopticResponse.SUMMARY.RESPONSE_CODE + '\' and message: \'' +
//             synopticResponse.SUMMARY.RESPONSE_MESSAGE + '\''
//         );
//     }

//     var observations = synopticResponse.STATION[0].OBSERVATIONS;

//     var intervals_flat = observations.precip_intervals_set_1d;
//     var interval_dates = observations.date_time;

//     var intervals = intervals_flat.reduce(function(ints, curr, idx) {
//         ints.push({
//             'precip': curr,
//             'last_report': interval_dates[idx]
//         })

//         return ints;
//     }, []);

//     if (!intervals) {
//         console.error('Precipitation response contains no intervals, cannot render view...');
//         return;
//     }

//     this.renderRainCounter(intervals);
//     this.renderGraph(intervals);
// }

// LandingController.prototype.renderRainCounter = function (intervals) {
//     var lastRainInterval = this._getLastSeenRainInterval(intervals);

//     if (!lastRainInterval) {
//         $('div[data-role="loading"]').remove();
//         $('p[data-role="days"]').html('&#8734;');
//         $('p[data-role="hours"]').html('&#8734;');
//         $('div[data-role="loading-date"]').remove();
//         $('strong[data-role="last-rain-date"]').remove();
//         $('h2[data-role="weather-breakdown-header"]').html('Nothing to look at down here, come back when weather is looking bleak.');

//         return;
//     }

//     var elapsedHours = lastRainInterval.elapsedHours;

//     var days = Math.floor(elapsedHours / 24);
//     var hours = elapsedHours % 24;

//     $('div[data-role="loading"]').remove();
//     $('p[data-role="days"]').html(days);
//     $('p[data-role="hours"]').html(hours);

//     if (days == 1) {
//         $('span[data-role="days-label"]').html('Day');
//     }

//     if (hours == 1) {
//         $('span[data-role="hours-label"]').html("Hour");
//     }

//     // Label just below hero image, saying the date it last rained
//     var dateOfRain = new Date(lastRainInterval.interval.last_report);

//     var month = this._getMonth(dateOfRain.getMonth());
//     var day = this._getOrdinalSuffix(dateOfRain.getDate());

//     $('div[data-role="loading-date"]').remove();
//     $('strong[data-role="last-rain-date"]').html(month + ' ' + day);
// }

// LandingController.prototype.renderGraph = function (intervals) {
//     var dailyIntervalLabel = function(tooltipItems, data) {
//         return ' ' + data.labels[tooltipItems.index].format('ll') + ' - ' + tooltipItems.yLabel.toFixedDown(3) + ' Inches of rain'
//     };
//     var hourlyIntervalLabel = function(tooltipItems, data) {
//         return ' ' + data.labels[tooltipItems.index].format('lll') + ' - ' + tooltipItems.yLabel.toFixedDown(3) + ' Inches of rain'
//     };

//     var timeSeriesDailyData = this._parseDailyIntervalsForGraph(intervals);
//     var timeSeriesHourlyData = this._parseHourlyIntervalsForGraph(intervals);

//     var timeSeriesCanvas = document.getElementById("timeSeries").getContext('2d');
//     var timeSeriesChart = new Chart(timeSeriesCanvas, {
//         type: 'bar',
//         data: {
//             labels: timeSeriesDailyData.labels,
//             datasets: [{
//                 label: 'Accumulated Precipitation (rolling 24 hours)',
//                 data: timeSeriesDailyData.data,
//                 backgroundColor: Chart.helpers.color('rgb(255, 99, 132)').alpha(0.5).rgbString(),
//                 type: 'bar',
//                 pointRadius: 0,
//                 fill: false,
//                 lineTension: 0,
//                 borderWidth: 2
//             }]
//         },
//         options: {
//             responsive: true,
//             maintainAspectRatio: false,
//             showTooltips: true,
//             scales: {
//                 xAxes: [{
//                     type: 'time',
//                     distribution: 'series',
//                     time: {
//                         unit: 'day',
//                         displayFormats: {
//                             'day': 'MMM DD',
//                             'hour': 'MMM D hA'
//                          }
//                     },
//                     ticks: {
//                         source: 'labels'
//                     }
//                 }],
//                 yAxes: [{
//                     scaleLabel: {
//                         display: true,
//                         labelString: 'Precipitation (in)'
//                     }
//                 }]
//             },
//             hover: {
//                 animationDuration: 400,
//                 axis: "x",
//                 intersect: true,
//                 mode: "label"
//             },
//             tooltips: {
//                 enabled: true,
//                 intersect: false,
//                 titleFontSize: 0,
//                 callbacks: {
//                     label: dailyIntervalLabel
//                 }
//             }
//         }
//     });

//     $('#graphSwitch').change(function() {
//         if ($(this).prop('checked')) {
//             timeSeriesChart.config.data.datasets[0].data = timeSeriesHourlyData.data;
//             timeSeriesChart.config.data.labels = timeSeriesHourlyData.labels;
//             timeSeriesChart.config.options.scales.xAxes[0].time.unit = 'hour';
//             timeSeriesChart.config.options.tooltips.callbacks.label = hourlyIntervalLabel;
//             timeSeriesChart.update();
//         } else {
//             timeSeriesChart.config.data.datasets[0].data = timeSeriesDailyData.data;
//             timeSeriesChart.config.data.labels = timeSeriesDailyData.labels
//             timeSeriesChart.config.options.scales.xAxes[0].time.unit = 'day';
//             timeSeriesChart.config.options.tooltips.callbacks.label = dailyIntervalLabel;
//             timeSeriesChart.update();
//         }
//     });
// }

// LandingController.prototype._parseDailyIntervalsForGraph = function (intervals) {
//     var data = [];
//     var labels = [];
//     var recent_first_intervals = intervals.reverse();

//     var accumulatedPrecip = intervals[0].precip;
//     var date = moment(intervals[0].last_report);

//     for (var i = 0; i < intervals.length; i++) {
//         var intDate = moment(intervals[i].last_report);

//         if (intDate.date() === date.date()) {
//             accumulatedPrecip += intervals[i].precip;
//         } else {
//             labels.push(date.endOf('day'));
//             data.push({
//                 t: date.valueOf(),
//                 y: accumulatedPrecip
//             });

//             date = moment(intervals[i].last_report);
//             accumulatedPrecip = intervals[i].precip;
//         }
//     }

//     return {
//         data: data,
//         labels: labels
//     };
// }

// LandingController.prototype._parseHourlyIntervalsForGraph = function (intervals) {
//     var data = [];
//     var labels = [];

//     // Find the time between two intervals in minutes
//     var intervalMiliseconds = moment(intervals[1].last_report) - moment(intervals[0].last_report);
//     var intervalMinutes = (intervalMiliseconds / 1000) / 60;
//     var intervalStep = Math.ceil(60 / intervalMinutes);

//     // Start pulling data 30 hours before the current interval
//     var intervalStart = intervals.length - intervalStep * 30;

//     for (var i = intervalStart, j = 0; j < 30; i += intervalStep, j += 1) {
//         var date = moment(intervals[i].last_report);

//         labels.push(date);
//         data.push({
//             t: date.valueOf(),
//             y: intervals[i].precip
//         });
//     }

//     return {
//         data: data,
//         labels: labels
//     };
// }

// LandingController.prototype._getLastSeenRainInterval = function (intervals) {
//     var runningIntervalCount = 0;

//     intervals = intervals.reverse();
//     for(var i = 0; i < intervals.length; i++) {
//         if (intervals[i].precip > 0) {
//             now = moment();
//             end_period = moment(intervals[i].last_report);
//             duration_between = moment.duration(now.diff(end_period));

//             return {
//                 'elapsedHours': parseInt(duration_between.asHours()),
//                 'interval': intervals[i]
//             };
//         }

//         runningIntervalCount++;
//     }

//     return null;
// }

// LandingController.prototype._getMonth = function (monthIndex) {
//     var months = [
//         "January", "February", "March", "April", "May", "June",
//         "July", "August", "September", "October", "November", "December"
//     ];

//     return months[monthIndex];
// }

// LandingController.prototype._getOrdinalSuffix = function (i) {
//     var j = i % 10,
//         k = i % 100;
//     if (j == 1 && k != 11) {
//         return i + "st";
//     }
//     if (j == 2 && k != 12) {
//         return i + "nd";
//     }
//     if (j == 3 && k != 13) {
//         return i + "rd";
//     }
//     return i + "th";
// }