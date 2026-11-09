import { defaults } from 'chart.js';

// The page tells climbers to wait 24 to 72 hours after rain, so the chart
// shades those windows behind the bars, newest (and darkest) first.
export const RAIN_WINDOWS = [
  { hours: 24, label: '24h', alpha: 0.14 },
  { hours: 48, label: '48h', alpha: 0.09 },
  { hours: 72, label: '72h', alpha: 0.05 }
];

const HOUR_MS = 60 * 60 * 1000;
const LABEL_FONT_SIZE = 11;
const LABEL_TOP_PADDING = 4;
const LABEL_SIDE_PADDING = 3;
const LABEL_COLOR = 'rgba(194, 24, 91, 0.75)';

// Where `time` falls on a category axis, as a fractional bar index: bar i
// covers values i - 0.5 to i + 0.5, and slots[i] = [startMs, endMs] is the
// time it covers. A time in a gap between slots (a missing hour) sits on the
// boundary before the next slot.
export const fractionalIndex = (slots, time) => {
  for (let i = 0; i < slots.length; i++) {
    const [start, end] = slots[i];
    if (time < start) return i - 0.5;
    if (time < end) return i - 0.5 + (time - start) / (end - start);
  }
  return slots.length - 0.5;
};

const clamp = (value, min, max) => Math.min(Math.max(value, min), max);

// A Chart.js plugin: an object of hooks Chart.js calls while it draws. The
// controller hands it chart.$rainWindows = { anchor, slots, gridIndices };
// what it draws is recorded on chart.$rainWindowsDrawn, for the tests.
//
// It also draws the vertical gridlines. Chart.js puts a gridline halfway
// between the date labels it keeps, so once a narrow screen skips every
// other label, the line lands in the middle of the skipped day's bar. These
// lines sit on bar boundaries (value i - 0.5) whichever labels show.
export const rainWindowsPlugin = {
  id: 'rainWindows',

  // After the axes, before the bars: everything here sits behind them
  beforeDatasetsDraw(chart) {
    const { ctx, chartArea, scales: { x } } = chart;
    const input = chart.$rainWindows;
    const drawn = { bands: [], labels: [], gridLines: [] };
    chart.$rainWindowsDrawn = drawn;

    if (!input || !input.slots.length) return;

    const height = chartArea.bottom - chartArea.top;
    const pixelFor = (time) => clamp(
      x.getPixelForValue(fractionalIndex(input.slots, time)),
      chartArea.left,
      chartArea.right
    );
    const anchor = input.anchor.getTime();

    ctx.save();

    RAIN_WINDOWS.forEach((window, i) => {
      // The newest band runs to the right edge: on the daily chart today's
      // slot is only part-way through, and nothing in the rest can mislead.
      const right = i === 0
        ? chartArea.right
        : pixelFor(anchor - RAIN_WINDOWS[i - 1].hours * HOUR_MS);
      const left = pixelFor(anchor - window.hours * HOUR_MS);
      if (right - left < 0.5) return;

      ctx.fillStyle = `rgba(255, 99, 132, ${window.alpha})`;
      ctx.fillRect(left, chartArea.top, right - left, height);
      drawn.bands.push({
        label: window.label,
        alpha: window.alpha,
        left,
        right,
        top: chartArea.top,
        bottom: chartArea.bottom
      });
    });

    ctx.strokeStyle = defaults.borderColor;
    ctx.lineWidth = 1;
    input.gridIndices.forEach((index) => {
      const lineX = x.getPixelForValue(index - 0.5);
      ctx.beginPath();
      ctx.moveTo(lineX, chartArea.top);
      ctx.lineTo(lineX, chartArea.bottom);
      ctx.stroke();
      drawn.gridLines.push(lineX);
    });

    ctx.restore();
  },

  // Each band's label, at the top. The y-axis headroom keeps bars below them.
  afterDatasetsDraw(chart) {
    const { ctx, chartArea } = chart;
    const drawn = chart.$rainWindowsDrawn;
    if (!drawn) return;

    const top = chartArea.top + LABEL_TOP_PADDING;

    ctx.save();
    ctx.font = `600 ${LABEL_FONT_SIZE}px ${defaults.font.family}`;
    ctx.fillStyle = LABEL_COLOR;

    drawn.bands.forEach((band) => {
      const textWidth = ctx.measureText(band.label).width;
      const bandWidth = band.right - band.left;
      const centre = (band.left + band.right) / 2;

      if (textWidth + 2 * LABEL_SIDE_PADDING <= bandWidth) {
        ctx.textAlign = 'center';
        ctx.textBaseline = 'top';
        ctx.fillText(band.label, centre, top);
        drawn.labels.push({
          text: band.label,
          rotated: false,
          left: centre - textWidth / 2,
          right: centre + textWidth / 2,
          top,
          bottom: top + LABEL_FONT_SIZE
        });
      } else if (LABEL_FONT_SIZE + 2 <= bandWidth) {
        // Too narrow for the text (a day on a phone): turn it to read upwards,
        // ending at the top, instead of spilling into the next band
        ctx.save();
        ctx.translate(centre, top);
        ctx.rotate(-Math.PI / 2);
        ctx.textAlign = 'right';
        ctx.textBaseline = 'middle';
        ctx.fillText(band.label, 0, 0);
        ctx.restore();
        drawn.labels.push({
          text: band.label,
          rotated: true,
          left: centre - LABEL_FONT_SIZE / 2,
          right: centre + LABEL_FONT_SIZE / 2,
          top,
          bottom: top + textWidth
        });
      }
    });

    ctx.restore();
  }
};
