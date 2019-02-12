particlesJS.load('particles-js', '/snow.json', $.noop);

fetchPrecipitationIntervals()
    .then(function (response) {
        if (response.SUMMARY.RESPONSE_CODE < 0) {
            console.error(response);
            return;
        }

        console.log(response);
        
        var totalHours = getHoursSinceRain(response.STATION[0].OBSERVATIONS.precipitation);
        var days = Math.floor(totalHours / 24);
        var hours = totalHours % 24;
        
        $('div[data-role="loading"]').remove();
        $('p[data-role="days"]').html(days);
        $('p[data-role="hours"]').html(hours);

        if (days == 1) {
            $('span[data-role="days-label"]').html('Day');
        }

        if (hours == 1) {
            $('span[data-role="hours-label"]').html("Hour");
        }
    });

function getHoursSinceRain(intervals) {
    if (!intervals) {
        console.error('Reponse failed');
    }

    var runningIntervalCount = 0;

    intervals = intervals.reverse();
    for(var i = 0; i < intervals.length; i++) {
        if (intervals[i].total > 0) {
            break;
        }

        runningIntervalCount++;
    }

    return runningIntervalCount;
}

function fetchPrecipitationIntervals() {
    return $.ajax({
        'method': 'GET',
        'url': 'https://api.synopticdata.com/v2/stations/precip',
        'data': {
            'token': '2153743de639465ebbb30fa392c748de',
            'stid': 'rrkn2',
            'recent': 43200,
            'units': 'english',
            'pmode': 'intervals',
            'interval': 'hour'
        },
        'dataType': 'json'
    });
}