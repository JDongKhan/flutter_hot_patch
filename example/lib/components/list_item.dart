import 'package:flutter/material.dart';

/// @author jd

class CommonListItem extends StatefulWidget {
  const CommonListItem({super.key, required this.index});

  final int index;

  @override
  State<CommonListItem> createState() => _CommonListItemState();
}

class _CommonListItemState extends State<CommonListItem> {

  @override
  void initState() {
    super.initState();
    print("listItem initState - ${widget.index}");
  }

  @override
  void didUpdateWidget(covariant CommonListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("listItem didUpdateWidget- ${widget.index}");
  }

  @override
  Widget build(BuildContext context) {
    return Text('builder item ${widget.index}');
  }
}
