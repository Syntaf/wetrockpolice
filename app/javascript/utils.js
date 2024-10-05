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