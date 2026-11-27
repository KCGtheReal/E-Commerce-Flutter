import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../models/catalog_models.dart';
import 'common_states.dart';

class ImageZoomModal extends StatefulWidget {
  const ImageZoomModal({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  final List<ProductImageDto> images;
  final int initialIndex;

  static Future<void> show(
    BuildContext context, {
    required List<ProductImageDto> images,
    int initialIndex = 0,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => ImageZoomModal(
        images: images,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  State<ImageZoomModal> createState() => _ImageZoomModalState();
}

class _ImageZoomModalState extends State<ImageZoomModal> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(
      0,
      widget.images.isEmpty ? 0 : widget.images.length - 1,
    );
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: AppColors.onyxBlack,
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: ResetNetworkImage(
                      imageUrl: widget.images[index].imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softCharcoal,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: AppTheme.monoStyle(
                    fontSize: 12,
                    color: AppColors.boneWhite,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.softCharcoal,
                  foregroundColor: AppColors.boneWhite,
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            if (widget.images.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List<Widget>.generate(widget.images.length, (i) {
                        final selected = i == _currentIndex;
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              i,
                              duration: AppMotion.stateTransition,
                              curve: AppMotion.curve,
                            );
                          },
                          child: Container(
                            width: 52,
                            height: 64,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadii.xs),
                              border: Border.all(
                                color: selected
                                    ? AppColors.terracotta
                                    : AppColors.darkBorder,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ResetNetworkImage(
                              imageUrl: widget.images[i].imageUrl,
                              fit: BoxFit.cover,
                              cacheWidth: 160,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
