/// B站视频信息模型
class VideoInfo {
  final String bvid;
  final String title;
  final String pic;
  final String ownerName;
  final int ownerMid;
  final int view;
  final int danmaku;
  final int like;
  final int coin;
  final int favorite;
  final int share;

  VideoInfo({
    required this.bvid,
    required this.title,
    required this.pic,
    required this.ownerName,
    required this.ownerMid,
    required this.view,
    required this.danmaku,
    required this.like,
    required this.coin,
    required this.favorite,
    required this.share,
  });

  factory VideoInfo.fromBilibiliApi(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final owner = data['owner'] as Map<String, dynamic>;
    final stat = data['stat'] as Map<String, dynamic>;

    return VideoInfo(
      bvid: data['bvid'] as String,
      title: data['title'] as String,
      pic: data['pic'] as String,
      ownerName: owner['name'] as String,
      ownerMid: owner['mid'] as int,
      view: stat['view'] as int,
      danmaku: stat['danmaku'] as int,
      like: stat['like'] as int,
      coin: stat['coin'] as int,
      favorite: stat['favorite'] as int,
      share: stat['share'] as int,
    );
  }
}
