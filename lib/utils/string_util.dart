import 'dart:math';

String loremIpsum = '';

class ImagePaths {
  static const String logo = 'assets/images/RentARide.png';
  static const String heritageBackground =
      'assets/images/heritage_background.jpg';
  static const String heritageIcon = 'assets/images/heritage_icon.png';
  static const String testimony = 'assets/images/testimony.png';
}

class StorageFields {
  static const String profilePics = 'profilePics';
  static const String windows = 'windows';
  static const String orders = 'orders';
  static const String galleries = 'galleries';
  static const String items = 'items';
}

class UserTypes {
  static const String client = 'CLIENT';
  static const String admin = 'ADMIN';
}

class Collections {
  static const String users = 'users';
  static const String faqs = 'faqs';
  static const String windows = 'windows';
  static const String transactions = 'transactions';
  static const String orders = 'orders';
  static const String galleries = 'galleries';
  static const String items = 'items';
  static const String cart = 'cart';
}

class UserFields {
  static const String email = 'email';
  static const String password = 'password';
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String userType = 'userType';
  static const String profileImageURL = 'profileImageURL';
  static const String mobileNumber = 'mobileNumber';
  static const String address = 'address';
  static const String bookmarks = 'bookmarks';
}

class ItemFields {
  static const String name = 'name';
  static const String price = 'price';
  static const String description = 'description';
  static const String imageURL = 'imageURL';
  static const String itemType = 'itemType';

  //  FURNITURE FIELDS
  static const String minWidth = 'minWidth';
  static const String maxWidth = 'maxWidth';
  static const String minHeight = 'minHeight';
  static const String maxHeight = 'maxHeight';
  static const String isAvailable = 'isAvailable';
  static const String windowFields = 'windowFields';
  static const String accessoryFields = 'accessoryFields';
}

class ItemTypes {
  static const String window = 'WINDOW';
  static const String door = 'DOOR';
  static const String rawMaterial = 'RAW MATERIAL';
}

class WindowFields {
  static const String name = 'name';
  static const String price = 'price';
  static const String description = 'description';
  static const String imageURL = 'imageURL';
  static const String minWidth = 'minWidth';
  static const String maxWidth = 'maxWidth';
  static const String minHeight = 'minHeight';
  static const String maxHeight = 'maxHeight';
  static const String isAvailable = 'isAvailable';
  static const String windowFields = 'windowFields';
  static const String accessoryFields = 'accessoryFields';
}

class WindowSubfields {
  static const String name = 'name';
  static const String isMandatory = 'isMandatory';
  static const String priceBasis = 'priceBasis';
  static const String brownPrice = 'brownPrice';
  static const String mattBlackPrice = 'mattBlackPrice';
  static const String mattGrayPrice = 'mattGrayPrice';
  static const String woodFinishPrice = 'woodFinishPrice';
  static const String whitePrice = 'whitePrice';
}

class WindowAccessorySubfields {
  static const String name = 'name';
  static const String price = 'price';
}

class OptionalWindowFields {
  static const String isSelected = 'isSelected';
  static const String optionalFields = 'optionalFields';
  static const String price = 'price';
}

class OrderBreakdownMap {
  static const String field = 'field';
  static const String breakdownPrice = 'breakdownPrice';
}

class WindowColors {
  static const String brown = 'BROWN';
  static const String white = 'WHITE';
  static const String mattBlack = 'MATT BLACK';
  static const String mattGray = 'MATT GRAY';
  static const String woodFinish = 'WOOD FINISH';
}

class TransactionFields {
  static const String clientID = 'clientID';
  static const String productID = 'productID';
  static const String paidAmount = 'paidAmount';
  static const String paymentMethod = 'paymentMethod';
  static const String proofOfPayment = 'proofOfPayment';
  static const String paymentStatus = 'paymentStatus';
  static const String paymentVerified = 'paymentVerified';
  static const String dateCreated = 'dateCreated';
  static const String dateApproved = 'dateApproved';
}

class OrderFields {
  static const String clientID = 'clientID';
  static const String windowID = 'windowID';
  static const String width = 'width';
  static const String height = 'height';
  static const String glassType = 'glassType';
  static const String color = 'color';
  static const String purchaseStatus = 'purchaseStatus';
  static const String datePickedUp = 'datePickedUp';
  static const String rating = 'rating';
  static const String mandatoryMap = 'mandatoryMap';
  static const String optionalMap = 'optionalMap';
  static const String windowOverallPrice = 'windowOverallPrice';
  static const String laborPrice = 'laborPrice';
  static const String quotationURL = 'quotationURL';
}

class FAQFields {
  static const String question = 'question';
  static const String answer = 'answer';
}

class OrderStatuses {
  static const String denied = 'DENIED';
  static const String generated = 'GENERATED';
  static const String pending = 'PENDING';
  static const String processing = 'PROCESSING';
  static const String forPickUp = 'FOR PICK UP';
  static const String pickedUp = 'PICKED UP';
}

class TransactionStatuses {
  static const String pending = 'PENDING';
  static const String approved = 'APPROVED';
  static const String denied = 'DENIED';
}

class CartFields {
  static const String clientID = 'clientID';
  static const String itemID = 'itemID';
  static const String quantity = 'quantity';
  static const String quotationID = 'quotationID';
}

class QuotationFields {
  static const String clientID = 'clientID';
  static const String itemID = 'windowID';
  static const String width = 'width';
  static const String height = 'height';
  static const String glassType = 'glassType';
  static const String color = 'color';
  static const String purchaseStatus = 'purchaseStatus';
  static const String dateCreated = 'dateCreated';
  static const String datePickedUp = 'datePickedUp';
  static const String mandatoryMap = 'mandatoryMap';
  static const String optionalMap = 'optionalMap';
  static const String itemOverallPrice = 'itemOverallPrice';
  static const String laborPrice = 'laborPrice';
  static const String quotationURL = 'quotationURL';
}

class GalleryFields {
  static const String galleryType = 'galleryType';
  static const String title = 'title';
  static const String content = 'content';
  static const String imageURL = 'imageURL';
}

class GalleryTypes {
  static const String service = 'service';
  static const String portfolio = 'portfolio';
  static const String testimonial = 'testimonial';
}

class PathParameters {
  static const String userID = 'userID';
  static const String itemID = 'itemID';
  static const String faqID = 'faqID';
  static const String orderID = 'orderID';
  static const String galleryID = 'galleryID';
}

String generateRandomHexString(int length) {
  final random = Random();
  final codeUnits = List.generate(length ~/ 2, (index) {
    return random.nextInt(255);
  });

  final hexString =
      codeUnits.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return hexString;
}

String formatPrice(double amount) {
  // Round the amount to two decimal places
  amount = double.parse((amount).toStringAsFixed(2));

  // Convert the double to a string and split it into whole and decimal parts
  List<String> parts = amount.toString().split('.');

  // Format the whole part with commas
  String formattedWhole = '';
  for (int i = 0; i < parts[0].length; i++) {
    if (i != 0 && (parts[0].length - i) % 3 == 0) {
      formattedWhole += ',';
    }
    formattedWhole += parts[0][i];
  }

  // If there's a decimal part, add it back
  String formattedAmount = formattedWhole;
  if (parts.length > 1) {
    formattedAmount += '.' + (parts[1].length == 1 ? '${parts[1]}0' : parts[1]);
  } else {
    // If there's no decimal part, append '.00'
    formattedAmount += '.00';
  }

  return formattedAmount;
}
