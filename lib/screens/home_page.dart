import 'package:flutter/material.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  Uri FEED_URL = Uri.parse("https://www.upwork.com/ab/feed/jobs/rss?contractor_tier=1%2C2&verified_payment_only=1&q=flutter&subcategory2_uid=531770282589057024&sort=recency&paging=0%3B50&api_params=1&securityToken=9969cd6986b1644bc413d24d0aacc58ea26f3730b5f5c3302d764dc18205613bcff19caf857982d9d08a946cdc453066e15ec7d4044411a0c556ff30396da51e&userUid=1158416647190958080&orgUid=1158416647195152385");

  RssFeed? _feed; // RSS Feed Object
  String? _title; // Place holder for appbar title.

  // Notification Strings
  static const String loadingMessage = 'Loading Feed...';
  static const String feedLoadErrorMessage = 'Error Loading Feed.';
  static const String feedOpenErrorMessage = 'Error Opening Feed.';

  final TextStyle _textStyle = const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                        );

  // Key for the RefreshIndicator
  // See the documentation linked below for info on the RefreshIndicatorState
  // class and the GloablKey class.
  // https://api.flutter.dev/flutter/widgets/GlobalKey-class.html
  // https://api.flutter.dev/flutter/material/RefreshIndicatorState-class.html
  GlobalKey<RefreshIndicatorState>? _refreshKey;


  // When the app is initialized, we setup our GlobalKey, set our title, and
  // call the load() method which loads the RSS feed and UI.
  @override
  void initState() {
    super.initState();
    _refreshKey = GlobalKey<RefreshIndicatorState>();
    _title = "boş";
    updateTitle(_title);
    load();
  }

isFeedEmpty() {
    return null == _feed || null == _feed!.items;
  }

  @override
  Widget build(BuildContext context) {
    print(_feed!.items![1].description!.replaceAll("<br >", ""));
    return Scaffold(
      appBar: AppBar(
          title: Text(_title!),
        ),
      body: isFeedEmpty()
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : RefreshIndicator(
            key: _refreshKey,
            child: list(),
            onRefresh: () => load(),
          ),
    );
  }

  // ==================== ListView Components ====================

  // ListView
  // Consists of two main widgets. A Container Widget displaying info about the
  // RSS feed and the ListView containing the RSS Data. Both contained in a
  // Column Widget.
  list() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Container displaying RSS feed info.
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(10.0),
              margin: const EdgeInsets.only(left: 5.0, right: 5.0),
              decoration: customBoxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Text(
                  //   "Link: " + _feed!.link!,
                  //   style: _textStyle
                  // ),
                  Text(
                    "Description: " + _feed!.description!,
                    style: _textStyle
                  ),
                  Text(
                    "Docs: " + _feed!.docs!,
                    style: _textStyle
                  ),
                  // Text(
                  //   "Last Build Date: " + _feed!.lastBuildDate!,
                  //   style: _textStyle
                  // ),
                ],
              ),
            ),
          ),
          // ListView that displays the RSS data.
          Expanded(
            flex: 3,
            child: ListView.builder(
              padding: const EdgeInsets.all(5.0),
              itemCount: _feed!.items!.length,
              itemBuilder: (BuildContext context, int index) {
                final item = _feed!.items![index];
                return Container(
                  margin: const EdgeInsets.only(
                    bottom: 10.0,
                  ),
                  decoration: customBoxDecoration(),
                  child: ListTile(
                    title: title(item.title),
                    subtitle: subtitle(item.pubDate!),
                    trailing: rightIcon(),
                    contentPadding: const EdgeInsets.all(5.0),
                    onTap: () => openFeed(item.link!),
                  ),
                );
              },
            ),
          ),
        ]);
  }

  // Method that returns the Text Widget for the title of our RSS data.
  title(title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
          ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Method that returns the Text Widget for the subtitle of our RSS data.
  subtitle(DateTime subTitle) {
    return Text(
      subTitle.toString(),
      style: const TextStyle(
          fontSize: 15.0,
          fontWeight: FontWeight.w300,),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Method that returns Icon Widget.
  rightIcon() {
    return const Icon(
      Icons.keyboard_arrow_right,
      size: 30.0,
    );
  }

  // Custom box decoration for the Container Widgets.
  BoxDecoration customBoxDecoration() {
    return BoxDecoration(
      border: Border.all(
        width: 1.0,
      ),
    );
  }

// ====================  End ListView Components ====================


  // Method to check if the RSS feed is empty.
  

  // Method to change the title as a way to inform the user what is going on
  // while retrieving the RSS data.
  updateTitle(title) {
    setState(() {
      _title = title;
    });
  }

  // Method to help refresh the RSS data.
  updateFeed(feed) {
    setState(() {
      _feed = feed;
    });
  }

  // Method to navigate to the URL of a RSS feed item.
  Future<void> openFeed(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: true,
        forceWebView: false,
      );
      return;
    }
    updateTitle(feedOpenErrorMessage);
  }
  // Method to load the RSS data.
  load() async {
    updateTitle(loadingMessage);
    loadFeed().then((result) {
      if (null == result || result.toString().isEmpty) {
        // Notify user of error.
        updateTitle(feedLoadErrorMessage);
        return;
      }
      // If there is no error, load the RSS data into the _feed object.
      updateFeed(result);
      // Reset the title.
      updateTitle("<Hacker News\\> | Jobs Feed");
    });
  }

  // Method to get the RSS data from the provided URL in the FEED_URL variable.
  Future<RssFeed?> loadFeed() async {
    try {
      final client = http.Client();
      final response = await client.get(FEED_URL);
      return RssFeed.parse(response.body);
    } catch (e) {
      // handle any exceptions here
    }
    return null;
  }
}