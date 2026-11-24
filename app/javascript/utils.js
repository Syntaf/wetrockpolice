export const toDateString = (date) => {
    return date.toLocaleString('en-US', { month: 'short', day: 'numeric' });
};

// How far back the hourly chart looks. Rain from several days ago still
// matters for wet sandstone (#118).
export const HOURLY_LOOKBACK_DAYS = 5;

const HOUR_MS = 60 * 60 * 1000;

// Each reading is the rain in the hour up to its timestamp, so its day is
// the day of the moment just before the stamp: one stamped exactly midnight
// (00:00) is the last hour of the day before. Returns that day's midnight.
const readingDay = (date) => {
    const justBefore = new Date(date.getTime() - 1);
    return new Date(justBefore.getFullYear(), justBefore.getMonth(), justBefore.getDate());
};

// One bar per calendar day (midnight to midnight in the viewer's time zone),
// each the sum of that day's hourly intervals. Not a rolling 24 hours. The
// last day is today so far. Each bar's label is its day's midnight.
//
// The readings start partway through a day (20 days back from the current
// time of day), so the first day is left out unless its first reading's hour
// began at its midnight: a partial total would pass for a whole day's.
export const parseDailyIntervals = (intervals) => {
    const data = [];

    intervals.forEach((interval) => {
        const date = new Date(interval.last_report);
        const dayStart = readingDay(date);
        const day = data[data.length - 1];

        if (day && day.label.getTime() === dayStart.getTime()) {
            day.value += interval.precip;
        } else {
            data.push({
                label: dayStart,
                value: interval.precip,
                complete: date.getTime() - HOUR_MS <= dayStart.getTime()
            });
        }
    });

    // Today, the last day, is labelled "so far"; any earlier first day must
    // be whole.
    if (data.length > 1 && !data[0].complete) data.shift();

    return data.map(({ label, value }) => ({ label, value }));
};

// Every hourly interval from the last `days` days, ending at the latest
// reading. Both providers already send one interval per hour.
export const parseHourlyIntervals = (intervals, days = HOURLY_LOOKBACK_DAYS) => {
    if (!intervals.length) return [];

    const latest = new Date(intervals[intervals.length - 1].last_report);
    const cutoff = latest.getTime() - days * 24 * HOUR_MS;

    return intervals
        .filter(interval => new Date(interval.last_report).getTime() > cutoff)
        .map(interval => ({
            label: new Date(interval.last_report),
            value: interval.precip
        }));
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
