import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/land_area_breakdown.dart';
import '../../../../core/utils/land_unit_system.dart';

/// Modern result card. Backwards compatible with the legacy [LandAreaResult]
/// type, but rebuilt with a cleaner, denser layout that calls out the
/// primary number, the breakdown chips, and the equivalent decimal form.
class LandAreaBreakdownWidget extends StatelessWidget {
  final LandAreaResult result;

  const LandAreaBreakdownWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (result.breakdown.isEmpty && result.remainderSqFt <= 0.01) {
      return const SizedBox.shrink();
    }

    final totalSqft =
        result.unitValues.entries.fold<double>(0, (acc, e) {
          final factor = _legacyFactor(e.key);
          return acc + e.value * factor;
        }) +
        result.remainderSqFt;
    final totalSqm = totalSqft * LandUnitSystem.sqMeterPerSqft;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF1B5E20), Color(0xFF2E7D32)]
              : const [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                loc.result,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              _CopyButton(text: _buildShareText(loc)),
            ],
          ),
          const SizedBox(height: 16),
          if (result.breakdown.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.breakdown.map((part) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    part,
                    style: const TextStyle(
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
            ),
          if (result.remainderSqFt > 0.01) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${result.remainderSqFt.toStringAsFixed(2)} ft²',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (result.lastUnitDecimal != null) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  '≈',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.lastUnitDecimal!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'ft²',
                  value: totalSqft.toStringAsFixed(2),
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              Expanded(
                child: _StatTile(
                  label: 'm²',
                  value: totalSqm.toStringAsFixed(2),
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              Expanded(
                child: _StatTile(
                  label: loc.acre,
                  value: (totalSqft / LandUnitSystem.sqftPerAcre)
                      .toStringAsFixed(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildShareText(AppLocalizations loc) {
    final buf = StringBuffer('${loc.result}: ');
    buf.write(result.breakdown.join(' + '));
    if (result.remainderSqFt > 0.01) {
      buf.write(' + ${result.remainderSqFt.toStringAsFixed(2)} ft²');
    }
    if (result.lastUnitDecimal != null) {
      buf.write(' ≈ ${result.lastUnitDecimal}');
    }
    return buf.toString();
  }

  /// Maps the legacy string id back to the canonical sq.ft factor.
  double _legacyFactor(String legacyId) {
    switch (legacyId) {
      case 'acre':
      case 'acres':
        return LandUnitSystem.sqftPerAcre;
      case 'bigha':
        return LandUnitSystem.sqftPerBigha;
      case 'katha':
        return LandUnitSystem.sqftPerKatha;
      case 'shatak':
        return LandUnitSystem.sqftPerShatak;
      case 'chotak':
        return LandUnitSystem.sqftPerChotak;
      case 'bighaMymensingh':
        return LandUnitSystem.sqftPerBighaMymensingh;
      case 'kathaMymensingh':
        return LandUnitSystem.sqftPerKathaMymensingh;
      default:
        return 0;
    }
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  final String text;
  const _CopyButton({required this.text});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('Copied'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.copy_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}
