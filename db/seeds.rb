ActiveRecord::Base.transaction do
  admin = User.create!(
    email: 'admin@wetrockpolice',
    password: 'password',
    super_admin: true,
    admin: true,
    approved: true
  )
  admin.confirm

  sncc = LocalClimbingOrg.create!(name: "Southern Nevada Climbers Coalition", slug: "sncc")
  bacc = LocalClimbingOrg.create!(name: "Bay Area Climbers Coalition", slug: "bacc")
  scma = LocalClimbingOrg.create!(name: "Southern California Mountaineers Association", slug: "scma")

  redrock = WatchedArea.create!(name: "Red Rock", slug: "redrock", local_climbing_org: sncc, park_type_word: "canyon", info_bubble_excerpt: "Precipitation data collected from Red Rock visitor center. Use your best judgement in determining whether this information is relevant to the climbing area you will be in.", landing_paragraph: "Generally, you should avoid climbing <strong>24</strong> to <strong>72</strong> hours after rain, depending on where you intend to climb. Sunny locations like <a href=\"https://www.mountainproject.com/area/105732132/sunny-and-steep\" target=\"_blank\">Sunny and Steep</a> or <a href=\"https://www.mountainproject.com/area/105813478/stratocaster-area\" target=\"_blank\">Stratocaster Wall</a> will need much less time to dry when compared to places like <a href=\"https://www.mountainproject.com/area/105732030/the-black-corridor\" target=\"_blank\">Black Corridor</a> <br><br> Las Vegas has <em>plenty</em> of rainy day options, with climbing that rivals Red Rock itself. If you've found yourself in town during a rainy week, check out <a href=\"https://www.ladylockoff.com/wet-sandstone\">Irene's great writeup</a> for what to do. <br><br> Not sure why you shouldn't climb when it's wet, or want to read more on how to determine when climbing is OK? Check out <a href=\"https://www.southernnevadaclimberscoalition.org/rain\" target=\"_blank\">SNCC's write up</a>", photo_credit_name: "das_gulde", photo_credit_link: "https://www.instagram.com/das_gulde/", longitude: "-115.4357", latitude: "36.1323", manual_warn: false, station: "RRKN2", webcam_stid: "1169663215")
  castlerock = WatchedArea.create!(name: "Castle Rock", slug: "castlerock", local_climbing_org: bacc, park_type_word: "state park", info_bubble_excerpt: "Precipitation data collected from weather station AV151. Use your best judgement in determining whether this information is relevant to the climbing area you will be in.", landing_paragraph: "The sandstone at Castle Rock State Park, and the park across the street Sandborn County Park, is Vaqueros Sandstone and becomes very delicate after it rains. Please wait a <strong>minimum of 24 hours</strong> after it rains before you begin climbing, more commonly <strong>48-72</strong> hours are required. If you are unsure, check the soil at the base of the rock. \r\n\r\nAt the base of a route or problem, scrape away the top layer of dirt. If the top 1\" to 2\" of soil are dry, that's a strong indication that the area has dried out.", photo_credit_name: "BACC", photo_credit_link: "https://www.instagram.com/bayareaclimberscoalition/", longitude: "-122.0983", latitude: "37.2288", manual_warn: false, station: "AV151", webcam_stid: nil)
  stoneypoint = WatchedArea.create!(name: "Stoney Point", slug: "stoneypoint", local_climbing_org: scma, park_type_word: "park", info_bubble_excerpt: "Precipitation data collected from the Chatsworth National Weather Service observation station. More information on how we collect this data is in the FAQs.", landing_paragraph: "The sandstone at Stoney Point is porous. Light rain takes <strong>at least 48 hours</strong> to dry. After heavy or consistent rain, avoid climbing for <strong>FIVE</strong> to <strong>SEVEN</strong> full days to allow the rock to dry out. <strong>This is not a guarantee</strong>, and climbers should check conditions at every feature before attempting to climb.<br/><br/><strong>At the base of a route or problem, scrape away the top layer of dirt. If the top 1\" to 2\" of soil are dry, that's a strong indication that the area has dried out.</strong><br/><br/>Stoney Point holds major historical significance for climbers. Many of America's luminaries cut their teeth here - Royal Robbins, Yvon Chouinard, Bob Kamps, Ron Kauk, John Long, and John Bachar, to name but a few. <strong>Please recreate responsibly so that others may enjoy this piece of history.</strong>", photo_credit_name: "riversimard", photo_credit_link: "https://www.instagram.com/riversimard/", longitude: "-118.6032", latitude: "34.2731", manual_warn: false, station: "E1734", webcam_stid: nil)

  limekiln = ClimbingArea.create!(location_attributes: {longitude: "-12694551", latitude: "4393243", mt_z: "11.4"}, name: "Limekiln", rock_type: "Limestone", description: "Lime Kiln Canyon is a limestone sport climbing area located just east of Mesquite, NV across the border in Arizona. It is composed of three main sectors: <br>  <br> The Grail which has many long, single pitch climbs of high quality vertical to slightly overhanging rock. There are also a handful of multi-pitch routes. Mostly shady. This is by far the most popular of the Lime Kiln crags. <br>  <br> The Sacred Trust which has a selection of single pitch climbs as well as a few 5+ pitch routes. This wall doesn't have quite the quality of rock as The Grail but there are still some fantastic climbs and plenty of sunshine makes it good for colder days. <br>  <br> The Back Walls which include all the climbing deep up canyon. These routes are mainly vertical and slightly slabby quality grey limestone where moderate grades abound. <br>  <br> Lime Kiln is best in the fall and spring. Winter is cold and summer is hot.  <br>  <br> Human waste is a problem both near The Grail and near the camping/parking areas. Please come prepared to pack your shit out.")
  charleston = ClimbingArea.create!(location_attributes: {longitude: "-12871278", latitude: "4338754", mt_z: ""}, name: "Mount Charleston", rock_type: "Limestone", description: "This is one of the premier/most controversial climbing destinations in the US, if hard limestone routes are what you're seeking. The beautiful surroundings, overhanging caves, and cooler temperatures make Mt. Charleston a welcomed escape from the desert heat of Las Vegas during the summer months. Mt. Charleston is most well-known for having chipped routes and its hard pocketed testpieces such as Jason Campbell's Soul Train: 5.14a, Chris Sharma's Hasta La Vista: 5.14b/c, and Dan McQuade's Infectious Groove: 5.13b. Other climbers of note who contributed to the excellent climbing up on the mountaintop include Tony Yaniro, Randy Marsh, Leo Henson, Terry Parish, Rob Mulligan, Joe Brooks, Francois LeGrand, Doug Englekirk, etc. etc. etc. Mt. Charleston also sports numerous other quality lines ranging from 5.10 and up, so if you are in Vegas and looking to avoid the scorching sun and overcrowding of Red Rocks, head 45 minutes north to this pine tree oasis.   Note: The majority of the information I've posted on Mt. Charleston came directly from the guidebook Islands In The Sky, and proper credit should be given to its authors; Dan McQuade, Randy Leavitt, and Mick Ryan.   Much of this area is in the Mount Charleston Wilderness Area. See the BLM Fact Sheet for a good overview of what it protects and what that limits, and the Forest Service page for other information. One important distinction for route developers is that it's illegal to use power drills in a wilderness area, and bad ethics to operate one within earshot of one. As always, check with and respect the local climbing community on what goes where before doing such things.")
  potosi = ClimbingArea.create!(location_attributes: {longitude: "-12857072", latitude: "4294664", mt_z: ""}, name: "Mount Potosi", rock_type: "Limestone", description: "Mount Potosi has at least a few different areas for sport climbing. The most prominent is the Clear Light Cave. There is also the Buena Vista wall, and maybe more by now. This area is relatively secluded and not very populated. The limestone is of relatively good quality. There are a plethora of routes from at least 5.10 to 5.14, with potential for harder routes.")
  keyhole = ClimbingArea.create!(location_attributes: {longitude: "-12790443", latitude: "4259834", mt_z: "10.7"}, name: "Keyhole Canyon", rock_type: "Granite", description: "Riddled with rock art, this remote climbing destination located between Boulder City and Searchlight is a beautiful place to spend an afternoon.<br><br>Keyhole Canyon is primarily a traditional climbing area; sport routes are few. The local ethics are such that retro-bolts and bolts added on rappel are typically removed pretty quickly.")
  lamadre = ClimbingArea.create!(location_attributes: {longitude: "-12839815", latitude: "4331167", mt_z: "11.9"}, name: "La Madre Range", rock_type: "Limestone", description: "The La Madre range consists of low-elevation limestone cliffs that are located very close to town. These cliffs are great for an afternoon climbing session, or an all day outing. There is a good diversity of difficulty ranges (5.8-5.13) found at the La Madre cliffs, and the rock quality is good, albeit VERY sharp in some places. However, don't let this deter you from climbing some of these lines, as some of the routes are GREAT!<br><br>The best time of year to climb at La Madre is from late fall to late spring, as the summer can be unbearably hot. Taking the extreme temperature changes of the desert into account, you can climb in the early morning or late evening so long as you avoid the direct sun.<br><br>Much of the information included in this description was derived from the guidebook \"Islands In The Sky,\" written by Dan McQuade, Randy Leavitt, and Mick Ryan. Proper credit should be given to these authors. If you find yourself climbing at these crags frequently, I would encourage you to pick up this guide, as it is excellent!")
  gorge = ClimbingArea.create!(location_attributes: {longitude: "-12671357", latitude: "4429316", mt_z: ""}, name: "Virgin River Gorge", rock_type: "Limestone", description: "There are two camps when it comes to the VRG: Those who scoff at the idea of ever climbing there and the die-hard few who swear it is the best climbing in the country. The truth is the VRG has some of the worst scenery of any climbing area, but some of the best rock. If you can get past not being able to hear yourself think (or your partner for that matter), ugly road cuts, graffiti, and sometimes inhospitable temperature extremes, you will be rewarded with difficult, sustained lines, fantastic movement, and plenty of hard climbing.<br><br>Grades pretty much start at 5.12 here, and the best lines are in the hard 12 and up range. Climbing exists on both the sunny, north side of the gorge (Sun Cave, Sun Wall, and Fossil Cave) and the shady south side (Mentor Cave, Planet Earth Wall, Blasphemy Wall). Bring draws and a 60 or 70m rope. Generally, climbing season is from October to April. Summer months are hot.")
  tamalpais = ClimbingArea.create!(location_attributes: {longitude: "-13645178", latitude: "4570112", mt_z: "12.5"}, name: "Mount Tamalpais", rock_type: "Granite", description: "Located high above the North Bay, Mt. Tamalpais was once the site of an old hotel. While the hotel is gone, an observation tower remains on the East peak, and is surrounded by jagged volcanic rock that holds some interesting climbing.")
  basin = ClimbingArea.create!(location_attributes: {longitude: "-13163195", latitude: "4034711", mt_z: nil}, name: "Los Angeles Basin", rock_type: "Varying", description: "The sprawling L.A. Basin, bound on the north by the Santa Monica Mountains, the Santa Ana Mountains to the east and south, and to the west by the Pacific Ocean, is home to more than 10 million residents. The city of Los Angeles itself (pop. 4 million) is the second largest in the United States (New York City is first).")
  mini = ClimbingArea.create!(location_attributes: {longitude: "-13229876", latitude: "4042506", mt_z: nil}, name: "Miniholland", rock_type: "Volcanic Breccia", description: "A half dozen high quality volcanic breccia boulders (like Malibu Creek), though only three see any regular activity. Some of the boulders are tall and steep and some are short and overhung but all of the rock here features lots of pockets of various sizes, fingers to fists. The landings tend to be good and free of obsticals with only a few exceptions. Definately a destination crag as a full days climbing can be had here for the easy to moderste grade climber. The locals take really good care of the area which is nice and clean and well landscaped. A couple of benches have been hauled down to Boulder 2 so please be respectful to these accoutrements.")
  point = ClimbingArea.create!(location_attributes: {longitude: "-13253587", latitude: "4040355", mt_z: nil}, name: "Point Mugu", rock_type: "Volcanic Breccia", description: "For decades, Point Mugu has been THE spot for area climbers to learn basic crack climbing technique. The little boulder by the highway is simply famous among Ventura- and some LA-County climbers...and as Steve Edwards said in the Santa Barbara/Ventura guidebook, \u0093If you don\u0092t confuse famous with good, you may not be disappointed.\u0094 Popular with travelers along PCH as well as with the locals, you can expect to share the site with other climbers.")
  horse = ClimbingArea.create!(location_attributes: {longitude: "-13136924", latitude: "4074817", mt_z: nil}, name: "Horse Flats", rock_type: "Granite", description: "Plethora of boulder and top rope problems. Usually secluded. Great granite rock! Camping within walking distance (100yds) Can be super cold in the winter. Great summer place to escape the heat and smog of the LA basin.")
  wheel = ClimbingArea.create!(location_attributes: {longitude: "-13085717", latitude: "4242025", mt_z: nil}, name: "Wagon Wheel", rock_type: "Granite", description: "Grey granite boulders in the middle of nowhere, Mojave Desert, stretching as far as the eye can see. Vast potential. Avoid this area on weekends and holidays as it gets overrun with OHVs.  Wagon Wheel is an established bouldering spot east of Ridgecrest. According to Southern Sierra Rock Climbing Domelands \"More than 1,000 problems have been done in Wagon Wheel as of 1992 alone.\" Wagon Wheel is also mentioned (with old topo) in Southern California Bouldering, by Craig Fry. Exploring the large number of boulders without a guide or topo is fun too!")
  rubidoux = ClimbingArea.create!(location_attributes: {longitude: "-13068017", latitude: "4026654", mt_z: nil}, name: "Mt. Rubidoux", rock_type: "Granite", description: "Mt. Rubidoux or simply Rubidoux is a large 161 acre boulder-covered hill that overlooks the City of Riverside and is a designated park and landmark. The 2009 road improvements greatly boosted the number of walkers, joggers, bicyclists, and climbers enjoying the slopes of Mt. Rubidoux.  Rubidoux's boulder-strewn hilltop offers not only the ubiquitous boulders, but there are slabs and blocks of light-colored quartz monzonite offering virtually endless quality boulder problems and top-ropes with famous dimes edges and relatively smooth texture.  In October of 1983 and 1984 Randy Vogel organized the Mt. Rubidoux Bouldering Contest and helped create new enthusiasm for climbing at Rubidoux that had diminished since the likes of Phil and Paul Gleason, the preternatural Phil Haney and Don O'Kelley frequented the hill since the 1960s, along with the famous dime-edge masters, Kevin Powell and Darrel Hensel in the 1980s & 90s. Numerous guidebooks by Steve Mackey (1976), Randy Vogel (1984 map), Paul Hellweg & Warstler (1988) and Craig Fry (1990) have documented and described the vast number of boulder problems, top-ropes, and climbing routes at Mt. Rudidoux.")
  woodson = ClimbingArea.create!(location_attributes: {longitude: "-13019927", latitude: "3896100", mt_z: nil}, name: "Mount Woodson", rock_type: "Granite", description: "Mount Woodson is a San Diego classic with short climbs on great granite. Woodson is made up of hundreds of boulders of all sizes. This area has been known in the past as a bouldering area. However, there are good top rope and lead climbs as well. Woodson has some great practice aid routes to train on. Woodson has a paved road that you can walk up and access the varies climbs as you walk to the antennas at the top of the mountain. Beware if you do not know where you are going you can end up doing a lot of bushwhacking to get to climbs.  Beyond the old classics, a lot of new traffic has brought about some outstanding albeit hard new classics.")
  newjackcity = ClimbingArea.create!(location_attributes: {longitude: "-13021931", latitude: "4118448", mt_z: nil}, name: "New Jack City", rock_type: "Metamorphic", description: "New Jack City (NJC), also known as Sawtooth Canyon, is a sport climbing destination near Barstow, CA. With more than 450 sport climbs ranging from 5.6 - 5.13 scattered across the high desert, New Jack City offers something for climbers of all abilities. The rock is an unusual form of metamorphic rock of volcanic origin, offering often tricky and thought-provoking sequences and moves on huecos, pockets, edges, jugs, underclings, and crimps. The climbing is typically steep and diverse, requiring both strength and technique. Located in the high desert the climbing season runs from October through May.")

  Faq.create!([
    {question: "Can I trust Wet Rock Police to always show accurate weather information?", answer: "Theoretically, yes. In reality, weather is a difficult thing to track and generalize. One should use their best judgement in determining whether the information shown on the landing page is both accurate and relevant to their climbing destination. If you're planning on climbing in Black Velvet for example, and are not sure if it rained, you may want to use other additional resources beyond this site such as a <a href=\"https://www.iweathernet.com/total-rainfall-map-24-hours-to-72-hours\" target=\"_blank\">radap map</a> or <a href=\"https://www.facebook.com/groups/ClimbVegas\" target=\"_blank\">local facebook group</a>.", watched_area: redrock},
    {question: "Will this site support other crags?", answer: "Depending on the area, yes, there are future plans to expand the site to help out other sandstone areas. Email <a href=\"mailto:grant@wetrockpolice.com\">grant@wetrockpolice.com</a> if you'd like your own crag to be considered.", watched_area: redrock},
    {question: "Where can I climb if it rained?", answer: "If you're looking to boulder, check out Indian Rock or Mortar Rock in Berkeley or Turtle Rock in Ring Mountain. If you want to sport climb, Remilliard Park, Cragmont, Mt St. Helena, or Ring Mountain are all great options. ", watched_area: castlerock},
    {question: "Where can I climb if it rained?", answer: "Depending on the month, Las Vegas has a handful of different rainy day options. See the <a href=\"/redrock/rainy-day-options\">Rainy Day Crags</a> page for more detailed information.", watched_area: stoneypoint},
    {question: "Where is the precipitation data coming from?", answer: "Precipitation data is pulled from a rain gauge at the National Weather Service <a href=\"https://www.weather.gov/wrh/timeseries?site=RRKN2\" target=\"_blank\">RRKN2</a> station, located at the Red Rock visitor center. Data is updated hourly, and supplied by Synoptic Data.", watched_area: redrock},
    {question: "Can I trust Wet Rock Police to always show accurate weather information?", answer: "Theoretically, yes. In reality, weather is a difficult thing to track and generalize. One should use their best judgement in determining whether the information shown on the landing page is both accurate and relevant to their climbing destination. If you aren't sure if it rained, you may want to use other additional resources beyond this site such as a <a href=\"https://www.iweathernet.com/total-rainfall-map-24-hours-to-72-hours\" target=\"_blank\">radar map</a> or visit the <a href=\"https://www.facebook.com/groups/149308231791732\" target=\"_blank\">Vegas Climbing</a> facebook group.", watched_area: stoneypoint},
    {question: "Where is the precipitation data coming from?", answer: "Precipitation data is pulled from a rain gauge at the National Weather Service <a href=\"https://www.weather.gov/wrh/timeseries?site=AV151\" target=\"_blank\">AV151</a> station. This station is roughly 3.3 miles southeast of the entrance to castle rock state park. Data is updated hourly, and supplied by Synoptic Labs.", watched_area: castlerock}
  ])
  RainyDayArea.create!([
    {climbing_area: newjackcity, watched_area: stoneypoint, driving_time: nil},
    {climbing_area: woodson, watched_area: stoneypoint, driving_time: nil},
    {climbing_area: rubidoux, watched_area: stoneypoint, driving_time: nil},
    {climbing_area: wheel, watched_area: stoneypoint, driving_time: nil},
    {climbing_area: horse, watched_area: stoneypoint, driving_time: nil},
    {climbing_area: point, watched_area: stoneypoint, driving_time: nil},
    {climbing_area: basin, watched_area: stoneypoint, driving_time: nil},
    {climbing_area: tamalpais, watched_area: castlerock, driving_time: nil},
    {climbing_area: gorge, watched_area: redrock, driving_time: 120},
    {climbing_area: lamadre, watched_area: redrock, driving_time: 15},
    {climbing_area: keyhole, watched_area: redrock, driving_time: 60},
    {climbing_area: potosi, watched_area: redrock, driving_time: 90},
    {climbing_area: charleston, watched_area: redrock, driving_time: 60},
    {climbing_area: limekiln, watched_area: redrock, driving_time: 120},
  ])
end
