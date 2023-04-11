# Dev super admin account

redrock_landing_paragraph = <<~EOS
                              Generally, you should avoid climbing <strong>24</strong> to <strong>72</strong> hours after rain, depending on where you intend to climb. Sunny locations like <a href="https://www.mountainproject.com/area/105732132/sunny-and-steep" target="_blank">Sunny and Steep</a> or <a href="https://www.mountainproject.com/area/105813478/stratocaster-area" target="_blank">Stratocaster Wall</a> will need much less time to dry when compared to places like <a href="https://www.mountainproject.com/area/105732030/the-black-corridor" target="_blank">Black Corridor</a> <br><br> Las Vegas has <em>plenty</em> of rainy day options, with climbing that rivals Red Rock itself. If you've found yourself in town during a rainy week, check out <a href="https://www.ladylockoff.com/wet-sandstone">Irene's great writeup</a> for what to do. <br><br> Not sure why you shouldn't climb when it's wet, or want to read more on how to determine when climbing is OK? Check out <a href="http://www.southernnevadaclimberscoalition.org/local-ethics/climbing-after-rain/" target="_blank">SNCC's write up</a>
                            EOS

User.new(
  :email => 'admin@localhost',
  :password => 'admin',
  :admin => true,
  :approved => true,
  :super_admin => true
).confirm
LocalClimbingOrg.create!([
  {
    name: "Southern Nevada Climbing Coalition",
    slug: "sncc"
  },
  {
    name: "Bay Area Climbers Coalition",
    slug: "bacc"
  }
])
WatchedArea.create!([
  {
    name: "Red Rock",
    slug: "redrock",
    park_type_word: 'canyon',
    landing_paragraph: redrock_landing_paragraph,
    info_bubble_excerpt: "Precipitation data collected from Red Rock visitor center. Use your best judgement in determening whether this information is relevant to the climbing area you will be in.",
    photo_credit_name: "das_gulde",
    photo_credit_link: "https://www.instagram.com/das_gulde/",
    longitude: "-115.4357",
    latitude: "36.1323",
    station: 'RRKN2',
    local_climbing_org_id: 1
  },
  {
    name: "Castle Rock",
    slug: "castlerock",
    park_type_word: 'area',
    landing_paragraph: 'lorem ipsum lorem ipsum loreum ipsum lorem ipsum',
    info_bubble_excerpt: "lorem ipsum lorem ipsum",
    photo_credit_name: "Nick Arnott",
    photo_credit_link: "/castlerock",
    longitude: "-122.0983",
    latitude: "37.2288",
    local_climbing_org_id: 2
  },
  {
    name: 'Stoney Point',
    slug: 'stoneypoint',
    park_type_word: 'area',
    landing_paragraph: 'lorem ipsum lorem ipsum loreum ipsum lorem ipsum',
    info_bubble_excerpt: 'lorem ipsum lorem ipsum loreum ipsum lorem ipsum',
    photo_credit_name: 'lorem',
    photo_credit_link: 'https://grantmercer.dev',
    longitude: '-118.6032',
    latitude: '34.2731',
    station: 'E1734',
    local_climbing_org_id: 2
  }
])
ClimbingArea.create!([
  {
    name: "Limekiln",
    rock_type: "Limestone",
    description: "Lime Kiln Canyon is a limestone sport climbing area located just east of Mesquite, NV across the border in Arizona. It is composed of three main sectors: <br>  <br> The Grail which has many long, single pitch climbs of high quality vertical to slightly overhanging rock. There are also a handful of multi-pitch routes. Mostly shady. This is by far the most popular of the Lime Kiln crags. <br>  <br> The Sacred Trust which has a selection of single pitch climbs as well as a few 5+ pitch routes. This wall doesn't have quite the quality of rock as The Grail but there are still some fantastic climbs and plenty of sunshine makes it good for colder days. <br>  <br> The Back Walls which include all the climbing deep up canyon. These routes are mainly vertical and slightly slabby quality grey limestone where moderate grades abound. <br>  <br> Lime Kiln is best in the fall and spring. Winter is cold and summer is hot.  <br>  <br> Human waste is a problem both near The Grail and near the camping/parking areas. Please come prepared to pack your shit out.",
    location_attributes: {
      longitude: "-12694551",
      latitude: "4393243",
      mt_z: "11.4",
      climbing_area_id: 1
    }
  },
  {
    name: "Mount Tamalpais",
    rock_type: "Granite",
    description: "Located high above the North Bay, Mt. Tamalpais was once the site of an old hotel. While the hotel is gone, an observation tower remains on the East peak, and is surrounded by jagged volcanic rock that holds some interesting climbing.",
    location_attributes: {
      longitude: "-13645178",
      latitude: "4570112",
      mt_z: "12.5",
      climbing_area_id: 2
    }
  }
])
RainyDayArea.create!([
  {climbing_area_id: 1, watched_area_id: 1, driving_time: 120},
  {climbing_area_id: 2, watched_area_id: 2, driving_time: 30},
  {climbing_area_id: 2, watched_area_id: 3, driving_time: 15}
])
Faq.create!([
  {
    question: "Where is the precipitation data coming from?",
    answer: "Precipitation data is pulled from a rain guage located at the Red Rock visitor center. Data is updated hourly, and supplied by Synoptic Labs.",
    watched_area_id: 1
  },
  {
    question: "Can I trust Wet Rock Police to always show accurate weather information?",
    answer: "Theoretically, yes. In reality, weather is a difficult thing to track and generalize. One should use their best judgement in determining whether the information shown on the landing page is both accurate and relevant to their climbing destination. If you're planning on climbing in Black Velvet for example, and are not sure if it rained, you may want to use other additional resources beyond this site such as a <a href=\"https://www.iweathernet.com/total-rainfall-map-24-hours-to-72-hours\" target=\"_blank\">radap map</a> or <a href=\"\" target=\"_blank\">local facebook group</a>.",
    watched_area_id: 1
  },
  {
    question: "Where can I climb if it rained?",
    answer: "Depending on the month, Las Vegas has a handful of different rainy day options. See the Rainy Day Crags page for more detailed information.",
    watched_area_id: 1
  },
  {
    question: "Will this site support other crags?",
    answer: "Depending on the area, yes, there are future plans to expand the site to help out other sandstone areas. Email gmercer015@gmail.com if you'd like your own crag to be considered.",
    watched_area_id: 1
  },
  {
    question: "Will this site support other crags?",
    answer: "Depending on the area, yes, there are future plans to expand the site to help out other sandstone areas. Email gmercer015@gmail.com if you'd like your own crag to be considered.",
    watched_area_id: 2
  }
])
JointMembershipApplication.create!([
  {
    first_name: 'John',
    last_name: 'Doe',
    email: 'johndoe@gmail.com',
    phone_number: 7024443333,
    street_line_one: '123 Main Street',
    street_line_two: 'Apt 2',
    city: 'Las Vegas',
    state: 'Nevada',
    zipcode: '89074',
    organization: 'Southern Nevada Climbing Coalition',
    amount_paid: '50',
    order_id: '12345GHT80#',
    paid_cash: false,
    pending: false,
    delivery_method: 'Local Pickup (Refuge)',
    shirt_orders_attributes: [
      {
        shirt_type: 'local_shirt',
        shirt_size: 'Mens Medium (Stone)',
        shirt_color: 'Stone'
      }
    ]
  }
])
RaffleEntry.create!([
  {
    contact: 'John Doe',
    email: 'johndoe@gmail.com',
    phone_number: 7021234567,
    amount_paid: 30,
    entries: 5,
    order_id: '1234FFF'
  }
])