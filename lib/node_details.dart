import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gql_http_link/gql_http_link.dart';
import 'schema/__generated__/device_info.data.gql.dart';
import 'schema/__generated__/device_info.req.gql.dart';
import 'package:ferry/ferry.dart';
import 'package:nsd/nsd.dart';
import 'mdns_chooser.dart';

// This is an immutable Widget that displays node information.

class _NodeInfo extends StatefulWidget {
  final Service node;

  const _NodeInfo(this.node, {Key? key}) : super(key: key);

  @override
  _State createState() => _State();
}

// This state object is necessary because, to display all the node information,
// we need to make two GraphQL requests to the node.

class _State extends State<_NodeInfo> {
  final EdgeInsets headerInsets =
      const EdgeInsets.only(top: 20.0, bottom: 8.0, left: 8.0);
  final EdgeInsets all8 = const EdgeInsets.all(8.0);

  List<GAllDriversData_driverInfo>? drivers;

  // Build the URI to the GraphQL query endpoint.

  late final queryLink = HttpLink(Uri(
          scheme: "http",
          host: widget.node.host,
          port: widget.node.port,
          path: propToString(widget.node, "queries"))
      .toString());

  final cache = Cache();

  late final client = Client(link: queryLink, cache: cache);

  @override
  void initState() {
    super.initState();

    client.request(GAllDriversReq((b) => b)).listen((response) {
      if (!response.loading) {
        final List<GAllDriversData_driverInfo> tmp =
            response.data?.driverInfo.toList() ?? [];

        tmp.sort((a, b) => a.name.compareTo(b.name));
        setState(() => drivers = tmp);
      }
    });
  }

  // Returns a widget that serves as a section header.

  Widget header(BuildContext context, String label) {
    return Padding(
      padding: headerInsets,
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  // Returns a widget that renders property information. This consists of a
  // dimmed label followed by its value in a highlighted color.

  Widget buildProperty(BuildContext context, String label, String? value) {
    final ThemeData td = Theme.of(context);

    return Row(
      children: [
        Flexible(
          fit: FlexFit.tight,
          flex: 8,
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(color: td.hintColor)),
        ),
        Container(width: 10.0),
        Flexible(
            fit: FlexFit.tight,
            flex: 20,
            child: Text(value ?? "unknown",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: td.indicatorColor)))
      ],
    );
  }

  // Returns a widget that displays the title of the page. The title
  // includes a gratuitous icon followed by the name of the node.

  Widget titleWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Row(children: [
        const Icon(Icons.developer_board),
        Container(width: 12.0),
        Text(widget.node.name ?? "** Unknown Name **",
            style: Theme.of(context).textTheme.titleLarge),
      ]),
    );
  }

  // Build the widget.

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: all8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget(context),
          Expanded(
            child: SingleChildScrollView(
              clipBehavior: Clip.hardEdge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildProperty(context, "location",
                      propToString(widget.node, "location")),
                  buildProperty(context, "address",
                      "${widget.node.host}:${widget.node.port}"),
                  header(context, "GraphQL Endpoints"),
                  buildProperty(
                      context, "queries", propToString(widget.node, "queries")),
                  buildProperty(context, "mutations",
                      propToString(widget.node, "mutations")),
                  buildProperty(context, "subscriptions",
                      propToString(widget.node, "subscriptions")),
                  header(context, "Drivers"),
                  drivers == null
                      ? const Center(child: CircularProgressIndicator())
                      : _DriversListView(drivers: drivers!),
                  header(context, "Devices"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Local widget which displays a list of drivers.

class _DriversListView extends StatelessWidget {
  const _DriversListView({
    Key? key,
    required this.drivers,
  }) : super(key: key);

  final List<GAllDriversData_driverInfo> drivers;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        clipBehavior: Clip.hardEdge,
        shrinkWrap: true,
        itemCount: drivers.length,
        itemBuilder: (context, index) {
          return Card(
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.only(left: 16.0, right: 8.0, bottom: 8.0),
            child: ListTile(
                title: Text(drivers[index].name),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: Text(drivers[index].summary),
                ),
                trailing: IconButton(
                    onPressed: () async {
                      return showDialog(
                        context: context,
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Card(
                                color: Theme.of(context).cardColor,
                                child: Column(
                                  children: [
                                    Expanded(
                                        child: Markdown(
                                            data: drivers[index].description)),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Close")),
                                    )
                                  ],
                                )),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.help))),
          );
        });
  }
}

// This public function returns the widget that displays node information.

Widget displayNode(Service node) => _NodeInfo(node);
