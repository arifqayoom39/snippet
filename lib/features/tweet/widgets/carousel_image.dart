import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:snippet/theme/pallete.dart';

class CarouselImage extends StatefulWidget {
  final List<String> imageLinks;
  final Function(int)? onImageTap; // Add this parameter

  const CarouselImage({
    Key? key,
    required this.imageLinks,
    this.onImageTap, // Add this parameter
  }) : super(key: key);

  @override
  State<CarouselImage> createState() => _CarouselImageState();
}

class _CarouselImageState extends State<CarouselImage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            CarouselSlider(
              items: widget.imageLinks.asMap().map((index, link) {
                return MapEntry(
                  index,
                  GestureDetector(
                    onTap: () {
                      if (widget.onImageTap != null) {
                        widget.onImageTap!(index);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      margin: const EdgeInsets.all(5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: CachedNetworkImage(
                          imageUrl: link,
                          fit: BoxFit.contain, // Changed to contain
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Pallete.greyColor.withOpacity(0.3),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Pallete.blueColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    ),
                  ),
                );
              }).values.toList(),
              options: CarouselOptions(
                viewportFraction: 1,
                enableInfiniteScroll: false,
                aspectRatio: 16 / 9,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
            if (widget.imageLinks.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widget.imageLinks.asMap().entries.map((e) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 3,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == e.key
                            ? Pallete.blueColor
                            : Pallete.greyColor.withOpacity(0.5),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
