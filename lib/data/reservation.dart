class Room {
  int id;
  String name;
  Room({this.id, this.name});
}

List<Room> rooms = [
  Room(id: 6, name: "Red Room"),
  Room(id: 2, name: "Blue Room"),
  Room(id: 5, name: "Green Room"),
  Room(id: 4, name: "Dark Room"),
];

class Customer {
  int id;
  String name;
  Customer({this.id, this.name});
}

List<Customer> cusomers = [
  Customer(id: 6, name: "Jan Jansen"),
  Customer(id: 2, name: "Cees Boomsma"),
  Customer(id: 5, name: "Piet Groten")
];

class Reservation {
  int id;
  DateTime fromDate;
  DateTime thruDate;
  int roomId;
  int customerId;
  String customerName;
  Reservation(
      {this.id,
      this.fromDate,
      this.thruDate,
      this.roomId,
      this.customerId,
      this.customerName});
}

List<Reservation> reservationsInput = [
  Reservation(
      id: 100,
      fromDate: DateTime(2020, 12, 29, 14, 0, 0, 0),
      thruDate: DateTime(2020, 12, 30, 14, 0, 0, 0),
      roomId: 1,
      customerId: 5,
      customerName: "jan Jansen"),
  Reservation(
      id: 106,
      fromDate: DateTime(2020, 11, 9, 14, 0, 0, 0),
      thruDate: DateTime(2020, 11, 27, 14, 0, 0, 0),
      roomId: 1,
      customerId: 5,
      customerName: "Piet lemmon"),
  Reservation(
      id: 102,
      fromDate: DateTime(2020, 11, 20, 14, 0, 0, 0),
      thruDate: DateTime(2020, 12, 1, 14, 0, 0, 0),
      roomId: 2,
      customerId: 6,
      customerName: "Jan de boer"),
  Reservation(
      id: 103,
      fromDate: DateTime(2020, 12, 5, 14, 0, 0, 0),
      thruDate: DateTime(2020, 12, 7, 14, 0, 0, 0),
      roomId: 2,
      customerId: 6,
      customerName: "Jan de boer"),
  Reservation(
      id: 104,
      fromDate: DateTime(2020, 12, 7, 14, 0, 0, 0),
      thruDate: DateTime(2020, 12, 9, 14, 0, 0, 0),
      roomId: 2,
      customerId: 6,
      customerName: "Jan de boer"),
  Reservation(
      id: 105,
      fromDate: DateTime(2020, 12, 29, 14, 0, 0, 0),
      thruDate: DateTime(2020, 12, 30, 14, 0, 0, 0),
      roomId: 3,
      customerId: 2,
      customerName: "Cees Jansma"),
  Reservation(
      id: 108,
      fromDate: DateTime(2020, 12, 22, 14, 0, 0, 0),
      thruDate: DateTime(2020, 12, 24, 14, 0, 0, 0),
      roomId: 4,
      customerId: 2,
      customerName: "1Hans de Groot"),
  Reservation(
      id: 107,
      fromDate: DateTime(2020, 12, 24, 14, 0, 0, 0),
      thruDate: DateTime(2020, 12, 28, 14, 0, 0, 0),
      roomId: 4,
      customerId: 2,
      customerName: "2Hans de Groot"),
];
