# products
Product.create(name: "カップラーメン", price: 130, image_path: "https://3.bp.blogspot.com/-rZMHLcW6Er4/WlGpO69KN7I/AAAAAAABJlg/KgmrOkMSuoM0Xf0qRil3iOpMlGer-ypmACLcBGAs/s800/food_cup_ramen_miso.png")
Product.create(name: "アイス", price: 100, image_path: "https://2.bp.blogspot.com/-t7fJ99VE-HY/W64DlIeosgI/AAAAAAABPH8/fzyUKstvUT0mu7Aqt1em7Lms0ttprj_tQCLcBGAs/s800/icecream_cup_spoon_wood.png")

# payment method
PaymentMethod.create(name: "cash")
PaymentMethod.create(name: "t-pay")

# purchases
Purchase.create(payment_method_id: 1)
Purchase.create(payment_method_id: 2)

# purchase items
PurchaseItem.create(purchase_id: 1, quantity: 2, product_id: 1, price: 100)
PurchaseItem.create(purchase_id: 2, quantity: 1, product_id: 2, price: 100)
