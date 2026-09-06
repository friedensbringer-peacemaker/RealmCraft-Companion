import Foundation
@main struct ChestSortingTests {
 static func main() {
  func chest(_ id: String, _ x: Int, _ y: Int, _ quantity: Int, dimension: String = "o", readable: Bool = true) -> ChestRecord {
   ChestRecord(id: id, dimension: dimension, x: x, y: y, z: 0, file: "fixture", items: [ChestItem(slot: 1, itemID: 3157, quantity: quantity, extraData: false), ChestItem(slot: 2, itemID: 12, quantity: 500, extraData: false)], readable: readable, error: "")
  }
  let a=chest("a",0,0,64), b=chest("b",3,4,128), c=chest("c",0,0,999,dimension:"n"), unknown=chest("u",1,0,999,readable:false)
  let predicate: (ChestItem)->Bool = { $0.itemID == 3157 }
  precondition(ChestSorting.quantity(a,matching:predicate)==64)
  precondition(ChestSorting.quantity(unknown,matching:predicate)==nil)
  precondition(ChestSorting.sorted([a,unknown,b],order:.most,reference:nil,matching:predicate).map(\.id)==["b","a","u"])
  precondition(ChestSorting.sorted([b,unknown,a],order:.least,reference:nil,matching:predicate).map(\.id)==["a","b","u"])
  precondition(ChestSorting.distance(b,from:a)==5)
  precondition(ChestSorting.distance(c,from:a)==nil)
  precondition(ChestSorting.sorted([c,b,a],order:.distance,reference:a,matching:predicate).map(\.id)==["a","b","c"])
  let tie=chest("d",0,0,64)
  precondition(ChestSorting.sorted([tie,a],order:.most,reference:nil,matching:predicate).map(\.id)==["a","d"])
  precondition(ChestSorting.sorted([],order:.most,reference:nil,matching:predicate).isEmpty)
  print("PASS: matching quantities, unknown-last, ascending/descending, 3D distance, dimension isolation, deterministic ties")
 }
}
