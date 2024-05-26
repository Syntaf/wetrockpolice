export const toFixedDown = (digits) => {
    const re = new RegExp("(\\d+\\.\\d{" + digits + "})(\\d)")
    const match = this.toString().match(re);
    return match ? parseFloat(match[1]) : this.valueOf();
};