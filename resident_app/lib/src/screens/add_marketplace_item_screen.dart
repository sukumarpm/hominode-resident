import 'package:flutter/material.dart';
import '../modals/create_listing_modal.dart';

class AddMarketplaceItemScreen extends StatelessWidget {
  const AddMarketplaceItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This screen is now replaced by the modal
    // Automatically show modal and pop this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pop();
      CreateListingModal.show(context);
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
