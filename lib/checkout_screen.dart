import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  final double cartTotal;
  final double cartDiscountedTotal;
  final List<dynamic> cartItems;

  const CheckoutScreen({
    super.key,
    required this.cartTotal,
    required this.cartDiscountedTotal,
    required this.cartItems,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  String _address = '';
  String _paymentMethod = 'Credit Card';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Shipping Address'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter Address' : null,
                onSaved: (newValue) => _address = newValue ?? '',
              ),
              DropdownButtonFormField(
                value: _paymentMethod,
                items: [
                  DropdownMenuItem(
                    value: 'Credit Card',
                    child: Text('Credit Card'),
                  ),
                  DropdownMenuItem(value: 'Paypal', child: Text('Paypal')),
                ],
                onChanged: (value) =>
                    setState(() => _paymentMethod = value ?? 'Credit Card'),
              ),
              SizedBox(height: 24),
              Text('Total: \$${widget.cartTotal.toStringAsFixed(2)}'),
              Text(
                'Discounted Total: \$${widget.cartDiscountedTotal.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.green),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    Navigator.pop(context, {
                      'address': _address,
                      'paymentMethod': _paymentMethod,
                    });
                  }
                },
                child: Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
