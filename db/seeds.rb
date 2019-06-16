User.create!([
  {email: "gmercer015@gmail.com", encrypted_password: "$2a$11$nNqNp//yyJ5m16BVqAH/OeCA9STXoGAbJU.caiRmaC7hWtwiVX49K", reset_password_token: nil, reset_password_sent_at: nil, remember_created_at: nil, admin: true, approved: true, confirmation_token: "GapE5tzHXAB_ZKus57CX", confirmed_at: "2019-06-10 00:36:00", confirmation_sent_at: "2019-06-10 00:32:50", unconfirmed_email: nil}
])
ClimbingArea.create!([
  {name: "Limekiln", rock_type: "Limestone", description: "Lime Kiln Canyon is a limestone sport climbing area located just east of Mesquite, NV across the border in Arizona. It is composed of three main sectors: <br>  <br> The Grail which has many long, single pitch climbs of high quality vertical to slightly overhanging rock. There are also a handful of multi-pitch routes. Mostly shady. This is by far the most popular of the Lime Kiln crags. <br>  <br> The Sacred Trust which has a selection of single pitch climbs as well as a few 5+ pitch routes. This wall doesn't have quite the quality of rock as The Grail but there are still some fantastic climbs and plenty of sunshine makes it good for colder days. <br>  <br> The Back Walls which include all the climbing deep up canyon. These routes are mainly vertical and slightly slabby quality grey limestone where moderate grades abound. <br>  <br> Lime Kiln is best in the fall and spring. Winter is cold and summer is hot.  <br>  <br> Human waste is a problem both near The Grail and near the camping/parking areas. Please come prepared to pack your shit out."}
])
Location.create!([
  {longitude: "-12694551", latitude: "4393243", mt_z: "11.4", climbing_area_id: 1}
])
RainyDayArea.create!([
  {climbing_area_id: 1, watched_area_id: 1, driving_time: 120}
])
WatchedArea.create!([
  {name: "Red Rock", slug: "redrock"}
])
