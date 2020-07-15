# Dev super admin account
User.new(
  :email => 'admin@localhost',
  :password => 'admin',
  :admin => true,
  :approved => true,
  :super_admin => true
).confirm
LocalClimbingOrg.create!([
  {name: "Southern Nevada Climbing Coalition", slug: "sncc"}
])
WatchedArea.create!([
  {name: "Red Rock", slug: "redrock", local_climbing_org_id: 1}
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
  }
])
RainyDayArea.create!([
  {climbing_area_id: 1, watched_area_id: 1, driving_time: 120}
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