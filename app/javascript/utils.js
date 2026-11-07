export const sameDate = (dateOne, dateTwo) => {
    return dateOne.getFullYear() === dateTwo.getFullYear() &&
        dateOne.getMonth() === dateTwo.getMonth() &&
        dateOne.getDate() === dateTwo.getDate();
};

export const toDateString = (date) => {
    return date.toLocaleString('en-US', { month: 'short', day: 'numeric' });
};

export const parseDailyIntervals = (intervals) => {
    const data = [];

    let accumulatedPrecip = intervals[0].precip;
    let date = new Date(intervals[0].last_report);

    for (let i = 0; i < intervals.length; i++) {

        const intDate = new Date(intervals[i].last_report);

        if (sameDate(date, intDate)) {
            accumulatedPrecip += intervals[i].precip;
        } else {
            data.push({
                label: date,
                value: accumulatedPrecip
            });

            date = new Date(intervals[i].last_report);
            accumulatedPrecip = intervals[i].precip;
        }
    }

    return data;
};

export const parseHourlyIntervals = (intervals) => {
    const data = [];

    // Find the time between two intervals in minutes
    const intervalMiliseconds =
        (new Date(intervals[1].last_report)) - (new Date(intervals[0].last_report));
    const intervalMinutes = (intervalMiliseconds / 1000) / 60;
    const intervalStep = Math.ceil(60 / intervalMinutes);

    // Start pulling data 30 hours before the current interval
    const intervalStart = intervals.length - intervalStep * 30;

    for (let i = intervalStart, j = 0; j < 30; i += intervalStep, j += 1) {
        const date = new Date(intervals[i].last_report);

        data.push({
            label: date,
            value: intervals[i].precip
        });
    }

    return data;
};

const median = (xs) => {
    if (!xs.length) return null;
    const s = [...xs].sort((a, b) => a - b);
    const mid = s.length >> 1;
    return s.length % 2 ? s[mid] : (s[mid - 1] + s[mid]) / 2;
};

// Hour by hour, the median of the models' rain at one point, so one model
// missing a storm (or inventing one) can't decide on its own. Each model's
// series is `hourly.precipitation_<model>`.
export const medianModelPrecip = (forecast, models) => {
    const hourly = forecast?.hourly ?? {};
    const series = models
        .map(m => hourly[`precipitation_${m}`])
        .filter(Array.isArray);

    return (hourly.time ?? []).map((_, i) =>
        median(series.map(s => s[i]).filter(v => v != null)));
};

// The most recent hour any point got modeled rain that the gauge can't have
// recorded, or null. `forecasts` is Open-Meteo's response for several points
// (an array, one entry per point, in the same order).
//
// Open-Meteo hours end on :00, the gauge's intervals end at :34, and model
// timing is often an hour or so off. So a model hour only counts when it
// STARTS more than `graceHours` after the gauge's last rain: the tail of a
// shower the gauge did catch never reads as one it missed.
export const findModelRainAfter = (forecasts, points, models, gaugeLastRain, now = new Date(), minMm = 0.1, graceHours = 1) => {
    const HOUR = 60 * 60 * 1000;
    const cutoff = gaugeLastRain ? gaugeLastRain.getTime() + graceHours * HOUR : null;
    let found = null;

    forecasts.forEach((forecast, idx) => {
        const times = forecast?.hourly?.time ?? [];
        const precip = medianModelPrecip(forecast, models);

        times.forEach((time, i) => {
            const at = new Date(time + 'Z'); // hour ending, UTC
            const mm = precip[i] ?? 0;

            if (at > now || mm < minMm) return;
            if (cutoff !== null && at.getTime() - HOUR <= cutoff) return;
            if (!found || at > found.at) found = { at, mm, name: points[idx].name };
        });
    });

    return found;
};
