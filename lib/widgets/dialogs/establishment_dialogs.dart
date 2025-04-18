import 'package:flutter/material.dart';
import '../../commons/decoration.dart';
import '../../models/establishment.dart';

/// Affiche une boîte de dialogue de confirmation pour supprimer un établissement des favoris.
Future<bool?> showDeleteEstablishmentDialog({
  required BuildContext context,
  required Establishment establishment,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Supprimer ce favori'),
        content: Text(
          'Voulez-vous retirer "${establishment.name}" de vos favoris ?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: Text(
              'Annuler',
              style: kRegular16.copyWith(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: Text(
              'Supprimer',
              style: kRegular16.copyWith(color: Colors.redAccent),
            ),
          ),
        ],
      );
    },
  );
}