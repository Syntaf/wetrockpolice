export const toFixedDown = (digits) => {
    const re = new RegExp("(\\d+\\.\\d{" + digits + "})(\\d)")
    const match = this.toString().match(re);
    return match ? parseFloat(match[1]) : this.valueOf();
};

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

// The most recent hour any point got rain in Open-Meteo's model, if it's
// newer than the gauge's last rain. `forecasts` is Open-Meteo's response for
// several points (an array, one entry per point, in the same order).
export const findModelRainAfter = (forecasts, points, gaugeLastRain, now = new Date(), minMm = 0.1) => {
    let found = null;

    forecasts.forEach((forecast, idx) => {
        const times = forecast?.hourly?.time ?? [];
        const precip = forecast?.hourly?.precipitation ?? [];

        times.forEach((time, i) => {
            const at = new Date(time + 'Z'); // hour ending, UTC
            const mm = precip[i] ?? 0;

            if (at > now || mm < minMm) return;
            if (gaugeLastRain && at <= gaugeLastRain) return;
            if (!found || at > found.at) found = { at, mm, name: points[idx].name };
        });
    });

    return found;
};
