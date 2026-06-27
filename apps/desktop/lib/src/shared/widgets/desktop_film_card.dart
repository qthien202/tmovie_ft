import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import '../desktop_design_system.dart';

class DesktopFilmCard extends StatefulWidget {
  final FilmItem film;
  final VoidCallback onTap;
  final double width;

  const DesktopFilmCard({
    super.key,
    required this.film,
    required this.onTap,
    this.width = 155,
  });

  @override
  State<DesktopFilmCard> createState() => _DesktopFilmCardState();
}

class _DesktopFilmCardState extends State<DesktopFilmCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final film = widget.film;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: DS.durationFast,
          curve: DS.curveFluid,
          child: SizedBox(
            width: widget.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster
                AspectRatio(
                  aspectRatio: DS.cardAspectRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: DS.primary.withValues(alpha: 0.25),
                                blurRadius: 20,
                                spreadRadius: 1,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppImage(
                            imageUrl: film.fullPosterUrl,
                            boxFit: BoxFit.cover,
                          ),
                          // Quality badge
                          if (film.quality != null)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  film.quality!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          // Episode badge
                          if (film.episodeCurrent != null)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Text(
                                  film.episodeCurrent!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          // Hover overlay
                          if (_isHovered)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    DS.primary.withValues(alpha: 0.15),
                                    Colors.transparent,
                                  ],
                                ),
                                border: Border.all(
                                  color: DS.primary.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      DS.primary.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Title
                Text(
                  film.name ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (film.year != null)
                  Text(
                    '${film.year}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
