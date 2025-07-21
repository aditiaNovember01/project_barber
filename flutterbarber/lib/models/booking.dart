class Booking {
  final int id;
  final int userId;
  final int barberId;
  final String bookingDate;
  final String bookingTime;
  final String status;
  final String amount;
  final String paymentStatus;
  final String proofOfPayment;
  final String createdAt;
  final String updatedAt;

  Booking({
    required this.id,
    required this.userId,
    required this.barberId,
    required this.bookingDate,
    required this.bookingTime,
    required this.status,
    required this.amount,
    required this.paymentStatus,
    required this.proofOfPayment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['user_id'],
      barberId: json['barber_id'],
      bookingDate: json['booking_date'],
      bookingTime: json['booking_time'],
      status: json['status'],
      amount: json['amount'].toString(),
      paymentStatus: json['payment_status'],
      proofOfPayment: json['proof_of_payment'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
} 