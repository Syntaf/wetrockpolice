// Hotwire
import "@hotwired/turbo-rails";

// Bootstrap (ESM build; Popper arrives via bootstrap's own import of
// @popperjs/core)
import "bootstrap";

// Stimulus — controllers registered explicitly (esbuild has no
// require.context; each identifier must match its data-controller attribute)
import { Application } from "@hotwired/stimulus";
import AsyncImageController from "./controllers/async_image_controller";
import RainyDayController from "./controllers/rainy_day_controller";
import ScrollToController from "./controllers/scroll_to_controller";
import TooltipController from "./controllers/tooltip_controller";
import WatchedAreaController from "./controllers/watched_area_controller";

window.Stimulus = Application.start();
Stimulus.register("async-image", AsyncImageController);
Stimulus.register("rainy-day", RainyDayController);
Stimulus.register("scroll-to", ScrollToController);
Stimulus.register("tooltip", TooltipController);
Stimulus.register("watched-area", WatchedAreaController);
