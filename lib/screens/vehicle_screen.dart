import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import 'document_detail_screen.dart';
import 'vehicle_form_screen.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  List<dynamic> _vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.listVehicles(
        familyRef: ApiService.instance.session.familyReferenceNumber,
      );
      setState(() {
        _vehicles = (data['vehicles'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar('Vehicles'),
      floatingActionButton: AppChromeScope.embedded(context)
          ? null
          : FloatingActionButton(
        backgroundColor: AppColors.navy,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
          ).then((_) => _load());
        },
        child: const Icon(Icons.add, color: AppColors.gold),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : _vehicles.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      EmptyState(message: 'No vehicles yet. Add one and attach the RC from Documents.'),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _vehicles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final map = _vehicles[index] as Map;
                      return AppCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.navy,
                            child: Icon(Icons.directions_car_outlined, color: AppColors.gold),
                          ),
                          title: Text(
                            '${map['make'] ?? ''} ${map['model'] ?? ''}'.trim(),
                            style: bodyStyle(weight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [
                              if ('${map['registration_number']}'.isNotEmpty) '${map['registration_number']}',
                              if (map['year'] != null) '${map['year']}',
                            ].join(' · '),
                            style: bodyStyle(size: 12, color: AppColors.grey),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            final docRef = '${map['rc_document_reference_number'] ?? ''}';
                            if (docRef.isEmpty) {
                              ErrorHandler.showError(context, 'No RC document attached');
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DocumentDetailScreen(documentRef: docRef),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
