function RedRockController(options) {
    this.options = $.extend(options, {
        'apiOptions': {
            'token': '2153743de639465ebbb30fa392c748de',
            'stid': 'rrkn2',
            'recent': 43200,
            'units': 'english',
            'pmode': 'intervals',
            'interval': 'hour'
        }
    });
}

RedRockController.prototype.initLandingView = function () {
    particlesJS.load('particles-js', '/snow.json', $.noop);
    AOS.init({duration: 1000});
    
    $('button[data-role="scroll-to-weather"]').click(function () {
        $('html, body').animate({
            scrollTop: $('.weather-breakdown').offset().top
        }, 700);
    });

    $('#weather-tooltip-warning').tooltip();

    this.fetchPrecipitation()
        .then(this.renderLandingView.bind(this));
}

RedRockController.prototype.fetchPrecipitation = function () {
    return $.ajax({
        'method': 'GET',
        'url': 'https://api.synopticdata.com/v2/stations/precip',
        'data': this.options.apiOptions,
        'dataType': 'json'
    });
}

RedRockController.prototype.renderLandingView = function (precipResponse) {
    if (precipResponse.SUMMARY.RESPONSE_CODE < 0) {
        console.error(precipResponse);
        return;
    }

    var intervals = precipResponse.STATION[0].OBSERVATIONS.precipitation

    this.renderRainCounter(intervals);
    this.renderGraph(intervals);
}

RedRockController.prototype.renderRainCounter = function (intervals) {
    var lastRainInterval = this._getLastSeenRainInterval(intervals);
    var elapsedHours = lastRainInterval.elapsedHours;

    var days = Math.floor(elapsedHours / 24);
    var hours = elapsedHours % 24;
    
    $('div[data-role="loading"]').remove();
    $('p[data-role="days"]').html(days);
    $('p[data-role="hours"]').html(hours);

    if (days == 1) {
        $('span[data-role="days-label"]').html('Day');
    }

    if (hours == 1) {
        $('span[data-role="hours-label"]').html("Hour");
    }

    // Label just below hero image, saying the date it last rained
    var dateOfRain = new Date(lastRainInterval.interval.last_report);
    var month = this._getMonth(dateOfRain.getMonth());
    var day = this._getOrdinalSuffix(dateOfRain.getDate());

    $('div[data-role="loading-date"]').remove();
    $('strong[data-role="last-rain-date"]').html(month + ' ' + day);
}

RedRockController.prototype.renderGraph = function (intervals) {
    var timeSeriesDailyData = this._parseDailyIntervalsForGraph(intervals);
    var timeSeriesHourlyData = this._parseHourlyIntervalsForGraph(intervals);

    var timeSeriesCanvas = document.getElementById("timeSeries").getContext('2d');
    var timeSeriesChart = new Chart(timeSeriesCanvas, {
        type: 'bar',
        data: {
            labels: timeSeriesDailyData.labels,
            datasets: [{
                label: 'Accumulated Precipitation (rolling 24 hours)',
                data: timeSeriesDailyData.data,
                backgroundColor: Chart.helpers.color('rgb(255, 99, 132)').alpha(0.5).rgbString(),
                type: 'bar',
                pointRadius: 0,
                fill: false,
                lineTension: 0,
                borderWidth: 2
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            showTooltips: true,
            scales: {
                xAxes: [{
                    type: 'time',
                    distribution: 'series',
                    time: {
                        unit: 'day',
                        displayFormats: {
                            'day': 'MMM DD',
                            'hour': 'MMM D hA'
                         }
                    },
                    ticks: {
                        source: 'labels'
                    }
                }],
                yAxes: [{
                    scaleLabel: {
                        display: true,
                        labelString: 'Precipitation (in)'
                    }
                }]
            },
            hover: {
                animationDuration: 400,
                axis: "x",
                intersect: true,
                mode: "label"
            },
            tooltips: {
                enabled: true,
                intersect: false,
                titleFontSize: 0,
                callbacks: {
                  label: function(tooltipItems, data) {
                    return ' ' + data.labels[tooltipItems.index].format('ll') + ' - ' + tooltipItems.yLabel.toFixedDown(3) + ' Inches of rain'
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
            timeSeriesChart.update();
        } else {
            timeSeriesChart.config.data.datasets[0].data = timeSeriesDailyData.data;
            timeSeriesChart.config.data.labels = timeSeriesDailyData.labels
            timeSeriesChart.config.options.scales.xAxes[0].time.unit = 'day';
            timeSeriesChart.update();
        }
    });
}

RedRockController.prototype._getLastSeenRainInterval = function (intervals) {
    if (!intervals) {
        console.error('Null value passed into _getLastSeenRainInterval');
        return;
    }

    var runningIntervalCount = 0;

    intervals = intervals.reverse();
    for(var i = 0; i < intervals.length; i++) {
        if (intervals[i].total > 0 && intervals[i].count !== null) {
            return {
                'elapsedHours': runningIntervalCount,
                'interval': intervals[i]
            };
        }

        runningIntervalCount++;
    }

    return null;
}

RedRockController.prototype._parseDailyIntervalsForGraph = function (intervals) {
    var data = [];
    var labels = [];

    var accumulatedPrecip = 0.0;
    var date = null;

    if (intervals[0].count !== null)
    {
        accumulatedPrecip = intervals[0].total;
        date = moment(intervals[0].last_report);
    }
    else
    {
        accumulatedPrecip = intervals[1].total;
        date = moment(intervals[1].last_report);
    }

    for (var i = 0; i < intervals.length; i++) {
        if (intervals[i].count === null)
            continue;

        var intDate = moment(intervals[i].last_report);

        if (intDate.date() === date.date()) {
            accumulatedPrecip += intervals[i].total;
        } else {
            labels.push(date.endOf('day'));
            data.push({
                t: date.valueOf(),
                y: accumulatedPrecip
            });

            date = moment(intervals[i].last_report);
            accumulatedPrecip = intervals[i].total;
        }
    }

    return {
        data: data,
        labels: labels
    };
}

RedRockController.prototype._parseHourlyIntervalsForGraph = function (intervals) {
    var data = [];
    var labels = [];

    for (var i = 0; i < 30; i++) {
        if (intervals[i].count === null)
            continue;

        var date = moment(intervals[i].last_report);

        labels.push(date);
        data.push({
            t: date.valueOf(),
            y: intervals[i].total
        });
    }

    return {
        data: data,
        labels: labels
    };
}

RedRockController.prototype._getMonth = function (monthIndex) {
    var months = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ];

    return months[monthIndex];
}

RedRockController.prototype._getOrdinalSuffix = function (i) {
    var j = i % 10,
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