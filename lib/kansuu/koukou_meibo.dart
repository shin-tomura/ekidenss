// ------------------------------------------------------------
// 高校の名簿(1.9.5。出身校と高校時代の実績。lib/kansuu/koukou.dart で使う)
//
// ・架空の高校。都道府県ごとに5校(全部で235校。番号は0から、保存するときは+1する。256校まで)。
//   実在の学校と同じ名前になっていることがあれば、名前だけ直してよい(並びと数は変えない。
//   並びを変えると、保存してある番号の高校が変わってしまう)。足すときは最後に足す
// ・校名は、SNSなどで話題にしやすいように、読みやすく打ちやすい名前にする(1.9.5で全235校を付け直した)
//   常用漢字と、鷲・燕・椿・桐・笹などのよく見る字だけを使い、読み方が1つに決まるものにする。
//   ふつうの学校は名字や地名らしい名前+商業・工業・農林・東西南北・第一など、
//   名門校・強豪校は短くて覚えやすい「〇〇学園」「〇〇学院」「〇〇実業」なども使う
// ・付け直した名前は、文部科学省の学校コードの全国の学校のデータ(school.teraren.com の検索)で
//   「校名+高等学校」を1校ずつ調べ、実在の高校と校名がそのまま同じものがないことを確かめた
//   (前の付け方のときに確かめた17校はそのまま残した。駅伝の強豪として有名な実在校に似た名前も避けた)
// ・名門度: 3名門(全国の常連。県外からも選手が来る) 2強豪 1中堅 0普通。名前のない部員の強さが変わる
// ・留学生: 名前のない留学生が1人いる(全国高校駅伝は2区か5区だけ。高校総体は5000mか3000m障害)。
//   大学に来る留学生の約半分は、この高校のどれかの出身になり、その年はその選手が名前のない留学生の代わりに走る
// ・色: 0スピード型 1駅伝型 2起伏型(クロカンに強い)。新入生がどの高校に入るかに少し効く
//   (スパート力が高い選手はスピード型、登り・下り・アップダウンが高い選手は起伏型に入りやすい)
// ・ゲーム本体の計算(大学のレース)には一切使わない
// ------------------------------------------------------------

/// 高校1校
class KoukouMei {
  /// 校名(「高」は付けない)
  final String mei;

  /// 都道府県の番号(LocationDatabase.allPrefectures の番号)
  final int ken;

  /// 名門度(3名門 2強豪 1中堅 0普通)
  final int meimon;

  /// 名前のない留学生がいるか
  final bool ryuugakusei;

  /// 色(0スピード型 1駅伝型 2起伏型)
  final int iro;

  /// 紹介文(名門校だけ。高校名鑑の画面に出す。1.9.5)
  final String shoukai;

  const KoukouMei(this.mei, this.ken, this.meimon, this.ryuugakusei, this.iro, {this.shoukai = ''});
}

/// 名門度の名前(0一般 1中堅 2強豪 3名門。高校名鑑の画面。1.9.5)
const List<String> koukouMeimonMei = ['一般', '中堅', '強豪', '名門'];

/// 色(タイプ)の名前(高校名鑑の画面。1.9.5)
const List<String> koukouIroMei = ['スピード型', '駅伝型', '起伏型'];

/// 色(タイプ)ごとの、集まりやすい選手(koukou.dart の _tokuiIro と合わせる。1.9.5)
const List<String> koukouIroKeikou = [
  'スパート力が高い選手',
  '能力に大きな偏りのない選手',
  '登り・下り・アップダウンが得意な選手',
];

/// 地区(全国高校駅伝の地区代表と、高校総体の地区大会の区切り。11地区)
const List<String> koukouChikuMei = [
  '北海道',
  '東北',
  '北関東',
  '南関東',
  '北信越',
  '東海',
  '近畿',
  '中国',
  '四国',
  '北九州',
  '南九州',
];

/// 都道府県ごとの地区の番号(LocationDatabase.allPrefectures の並び)
const List<int> koukouKenChiku = [
  0, // 北海道
  1, 1, 1, 1, 1, 1, // 東北
  2, 2, 2, 2, // 茨城・栃木・群馬・埼玉
  3, 3, 3, // 千葉・東京・神奈川
  4, 4, 4, 4, // 新潟・富山・石川・福井
  3, // 山梨
  4, // 長野
  5, 5, 5, 5, // 岐阜・静岡・愛知・三重
  6, 6, 6, 6, 6, 6, // 近畿
  7, 7, 7, 7, 7, // 中国
  8, 8, 8, 8, // 四国
  9, 9, 9, // 福岡・佐賀・長崎
  10, // 熊本
  9, // 大分
  10, 10, 10, // 宮崎・鹿児島・沖縄
];

/// 都道府県ごとの、予選に出る名前のない高校の数(人口に合わせた数。名簿の5校とは別)
const List<int> koukouKenSonota = [
  16, 7, 7, 9, 6, 6, 8, 11, 8, 8, // 北海道〜埼玉の手前
  22, 19, 30, 27, 9, 6, 6, 5, 6, 9, // 埼玉〜長野
  8, 13, 22, 8, 7, 10, 26, 17, 7, 6, // 岐阜〜和歌山
  5, 5, 8, 10, 7, 5, 6, 7, 5, 16, // 鳥取〜福岡
  6, 7, 8, 6, 6, 7, 7, // 佐賀〜沖縄
];

/// 高校の名簿(都道府県の並びで5校ずつ)
const List<KoukouMei> koukouMeibo = [
  KoukouMei('北風学園', 0, 3, false, 2, shoukai: '雪の残る林道の起伏で脚を鍛える、北の名門。冬の長い走り込みで、登りにも下りにも強い選手が育つ。'), // 北海道
  KoukouMei('大地学院', 0, 2, true, 2), // 北海道
  KoukouMei('森川商業', 0, 1, false, 1), // 北海道
  KoukouMei('北原南', 0, 1, false, 1), // 北海道
  KoukouMei('青野総合', 0, 0, false, 0), // 北海道
  KoukouMei('春風学園', 1, 3, false, 0, shoukai: 'トラックで切り替えの速さを磨く名門。ラストの競り合いに強い選手が育ち、最後の直線で勝負を決める。'), // 青森県
  KoukouMei('白雲学院', 1, 2, false, 2), // 青森県
  KoukouMei('中沢東', 1, 1, false, 1), // 青森県
  KoukouMei('柿沢農林', 1, 1, false, 2), // 青森県
  KoukouMei('岩沢第一', 1, 0, false, 2), // 青森県
  KoukouMei('星空学園', 2, 3, false, 1, shoukai: '満天の星の下、夜明け前の朝練から一日が始まる。7人でつなぐたすきを何より大切にする校風。'), // 岩手県
  KoukouMei('山風学院', 2, 2, false, 2), // 岩手県
  KoukouMei('月見商業', 2, 1, false, 1), // 岩手県
  KoukouMei('菊田第一', 2, 1, false, 1), // 岩手県
  KoukouMei('栗林北', 2, 0, false, 1), // 岩手県
  KoukouMei('若葉学院', 3, 3, false, 1, shoukai: '杜の都の名門。入ってきた選手を3年かけてじっくり育てる、面倒見の良さで知られる。'), // 宮城県
  KoukouMei('海風館', 3, 2, false, 0), // 宮城県
  KoukouMei('石浜商業', 3, 1, false, 1), // 宮城県
  KoukouMei('竹沢商業', 3, 1, false, 1), // 宮城県
  KoukouMei('花田', 3, 0, false, 0), // 宮城県
  KoukouMei('雪野商業', 4, 2, false, 0), // 秋田県
  KoukouMei('稲穂実業', 4, 2, false, 0), // 秋田県
  KoukouMei('杉山学院', 4, 1, false, 2), // 秋田県
  KoukouMei('秋山第一', 4, 1, false, 2), // 秋田県
  KoukouMei('梅野商業', 4, 0, false, 1), // 秋田県
  KoukouMei('花笠学院', 5, 2, false, 0), // 山形県
  KoukouMei('紅花義塾', 5, 2, true, 0), // 山形県
  KoukouMei('横山南', 5, 1, false, 2), // 山形県
  KoukouMei('竹野商業', 5, 1, false, 1), // 山形県
  KoukouMei('高沢西', 5, 0, false, 2), // 山形県
  KoukouMei('若駒学院', 6, 3, false, 0, shoukai: '若い駒のように駆ける、スピード自慢の名門。短い区間での爆発力に定評がある。'), // 福島県
  KoukouMei('白波学院', 6, 2, false, 1), // 福島県
  KoukouMei('杉沢', 6, 1, false, 1), // 福島県
  KoukouMei('山里東', 6, 1, false, 2), // 福島県
  KoukouMei('夕日学園', 6, 0, false, 1), // 福島県
  KoukouMei('星川学院', 7, 2, false, 1), // 茨城県
  KoukouMei('山桜学園', 7, 2, false, 2), // 茨城県
  KoukouMei('松坂', 7, 1, false, 0), // 茨城県
  KoukouMei('高台義塾', 7, 1, false, 2), // 茨城県
  KoukouMei('麦田第一', 7, 0, false, 0), // 茨城県
  KoukouMei('天馬学園', 8, 3, true, 2, shoukai: '山あいのクロスカントリーコースで鍛える名門。留学生と日本人の選手が、同じ坂道で競い合う。'), // 栃木県
  KoukouMei('大鷹学院', 8, 2, true, 1), // 栃木県
  KoukouMei('桜坂東', 8, 1, false, 1), // 栃木県
  KoukouMei('森野第二', 8, 1, false, 1), // 栃木県
  KoukouMei('石沢工業', 8, 0, false, 2), // 栃木県
  KoukouMei('風見学園', 9, 2, false, 1), // 群馬県
  KoukouMei('青柳商業', 9, 2, true, 1), // 群馬県
  KoukouMei('梅原第二', 9, 1, false, 0), // 群馬県
  KoukouMei('杉野農林', 9, 1, false, 2), // 群馬県
  KoukouMei('竹宮商業', 9, 0, false, 1), // 群馬県
  KoukouMei('青空学園', 10, 3, false, 1, shoukai: '広い河川敷を練習場にする名門。のびのびとした練習から、どの区間も任せられる選手が育つ。'), // 埼玉県
  KoukouMei('山吹学院', 10, 2, false, 2), // 埼玉県
  KoukouMei('丘野学舎', 10, 1, false, 2), // 埼玉県
  KoukouMei('沢田総合', 10, 1, false, 2), // 埼玉県
  KoukouMei('菊野', 10, 0, false, 1), // 埼玉県
  KoukouMei('潮風学園', 11, 3, false, 1, shoukai: '海沿いの道で潮風を受けながら走り込む名門。苦しい場面でも崩れない粘りが持ち味。'), // 千葉県
  KoukouMei('菜の花学院', 11, 2, false, 1), // 千葉県
  KoukouMei('海野総合', 11, 1, false, 1), // 千葉県
  KoukouMei('松浜総合', 11, 1, false, 1), // 千葉県
  KoukouMei('栗田農林', 11, 0, false, 2), // 千葉県
  KoukouMei('若竹学園', 12, 3, false, 2, shoukai: '都会の名門だが、練習の拠点は郊外の丘陵地。竹のようにしなやかな脚で、坂道を苦にしない。'), // 東京都
  KoukouMei('虹橋中央', 12, 2, true, 0), // 東京都
  KoukouMei('梅台西', 12, 1, false, 2), // 東京都
  KoukouMei('山森総合', 12, 1, false, 2), // 東京都
  KoukouMei('緑野西', 12, 0, false, 1), // 東京都
  KoukouMei('浜風学院', 13, 3, false, 0, shoukai: '海辺のトラックでスピードを磨く名門。前半から積極的に攻める走りが伝統。'), // 神奈川県
  KoukouMei('木立学園', 13, 2, false, 2), // 神奈川県
  KoukouMei('椿浦商業', 13, 1, false, 1), // 神奈川県
  KoukouMei('杉浦農林', 13, 1, false, 0), // 神奈川県
  KoukouMei('森下農林', 13, 0, false, 2), // 神奈川県
  KoukouMei('熊坂農林', 14, 2, false, 0), // 新潟県
  KoukouMei('雪国学舎', 14, 2, false, 1), // 新潟県
  KoukouMei('石原西', 14, 1, false, 0), // 新潟県
  KoukouMei('岡村南', 14, 1, false, 1), // 新潟県
  KoukouMei('米田農林', 14, 0, false, 0), // 新潟県
  KoukouMei('立野商業', 15, 2, false, 0), // 富山県
  KoukouMei('立浪実業', 15, 2, false, 0), // 富山県
  KoukouMei('宮下北', 15, 1, false, 1), // 富山県
  KoukouMei('川瀬農林', 15, 1, false, 1), // 富山県
  KoukouMei('若鮎学園', 15, 0, false, 2), // 富山県
  KoukouMei('金星館', 16, 2, false, 2), // 石川県
  KoukouMei('朝霧学院', 16, 2, false, 1), // 石川県
  KoukouMei('若菜学園', 16, 1, false, 1), // 石川県
  KoukouMei('千鳥学園', 16, 1, false, 1), // 石川県
  KoukouMei('森崎', 16, 0, false, 0), // 石川県
  KoukouMei('流星学園', 17, 3, false, 1, shoukai: '北陸の名門。全国の舞台で、流れ星のように一気に順位を上げる走りを目指す。'), // 福井県
  KoukouMei('岡野西', 17, 2, false, 1), // 福井県
  KoukouMei('石丸東', 17, 1, false, 0), // 福井県
  KoukouMei('谷口東', 17, 1, false, 1), // 福井県
  KoukouMei('笹野北', 17, 0, false, 0), // 福井県
  KoukouMei('風林学院', 18, 3, false, 1, shoukai: '疾きこと風のごとく、静かなること林のごとく。速さと落ち着きを兼ね備えた走りを目指す。'), // 山梨県
  KoukouMei('水晶学院', 18, 2, false, 0), // 山梨県
  KoukouMei('山彦館', 18, 1, false, 1), // 山梨県
  KoukouMei('坂田北', 18, 1, false, 1), // 山梨県
  KoukouMei('熊崎', 18, 0, false, 1), // 山梨県
  KoukouMei('雷鳥館', 19, 2, false, 1), // 長野県
  KoukouMei('高原学舎', 19, 2, false, 1), // 長野県
  KoukouMei('小沢工業', 19, 1, false, 1), // 長野県
  KoukouMei('峰岸北', 19, 1, false, 2), // 長野県
  KoukouMei('平沢第一', 19, 0, false, 2), // 長野県
  KoukouMei('清流学園', 20, 2, true, 1), // 岐阜県
  KoukouMei('村瀬第二', 20, 2, false, 1), // 岐阜県
  KoukouMei('森沢農林', 20, 1, false, 2), // 岐阜県
  KoukouMei('北浜第一', 20, 1, false, 2), // 岐阜県
  KoukouMei('野村北', 20, 0, false, 1), // 岐阜県
  KoukouMei('若潮学園', 21, 2, false, 0), // 静岡県
  KoukouMei('宮田第二', 21, 2, false, 0), // 静岡県
  KoukouMei('杉田農林', 21, 1, false, 2), // 静岡県
  KoukouMei('西浜総合', 21, 1, false, 1), // 静岡県
  KoukouMei('熊沢商業', 21, 0, false, 1), // 静岡県
  KoukouMei('藤川東', 22, 2, false, 0), // 愛知県
  KoukouMei('青竹義塾', 22, 2, false, 2), // 愛知県
  KoukouMei('森本西', 22, 1, false, 1), // 愛知県
  KoukouMei('西浦商業', 22, 1, false, 2), // 愛知県
  KoukouMei('若草学園', 22, 0, false, 1), // 愛知県
  KoukouMei('真珠商業', 23, 2, false, 0), // 三重県
  KoukouMei('岩本第一', 23, 2, false, 2), // 三重県
  KoukouMei('浜口中央', 23, 1, false, 2), // 三重県
  KoukouMei('池野工業', 23, 1, false, 0), // 三重県
  KoukouMei('坂口西', 23, 0, false, 2), // 三重県
  KoukouMei('水鳥学園', 24, 3, false, 1, shoukai: '湖のほとりの周回路で走り込む名門。水鳥の群れのように隊列を組む、集団走の練習が名物。'), // 滋賀県
  KoukouMei('長沢実業', 24, 2, false, 0), // 滋賀県
  KoukouMei('中井農林', 24, 1, false, 2), // 滋賀県
  KoukouMei('清川学院', 24, 1, false, 1), // 滋賀県
  KoukouMei('芝野工業', 24, 0, false, 1), // 滋賀県
  KoukouMei('松風義塾', 25, 2, false, 1), // 京都府
  KoukouMei('都実業', 25, 2, false, 1), // 京都府
  KoukouMei('堀井工業', 25, 1, false, 0), // 京都府
  KoukouMei('北島', 25, 1, false, 0), // 京都府
  KoukouMei('広瀬第二', 25, 0, false, 1), // 京都府
  KoukouMei('太陽学院', 26, 3, false, 1, shoukai: '明るく元気な校風の名門。どんな展開でも、最後まで前を向いてたすきをつなぐ。'), // 大阪府
  KoukouMei('山並学園', 26, 2, false, 2), // 大阪府
  KoukouMei('中島北', 26, 1, false, 1), // 大阪府
  KoukouMei('早瀬第二', 26, 1, false, 2), // 大阪府
  KoukouMei('朝顔学園', 26, 0, false, 2), // 大阪府
  KoukouMei('高見館', 27, 2, false, 2), // 兵庫県
  KoukouMei('浜辺学院', 27, 2, true, 1), // 兵庫県
  KoukouMei('湯川学院', 27, 1, false, 1), // 兵庫県
  KoukouMei('野口中央', 27, 1, false, 2), // 兵庫県
  KoukouMei('西沢南', 27, 0, false, 1), // 兵庫県
  KoukouMei('高畑総合', 28, 2, false, 2), // 奈良県
  KoukouMei('岩崎第一', 28, 2, false, 2), // 奈良県
  KoukouMei('万葉義塾', 28, 1, false, 1), // 奈良県
  KoukouMei('森島中央', 28, 1, false, 0), // 奈良県
  KoukouMei('森口', 28, 0, false, 1), // 奈良県
  KoukouMei('黒潮学園', 29, 2, true, 2), // 和歌山県
  KoukouMei('潮見実業', 29, 2, false, 1), // 和歌山県
  KoukouMei('夏空学園', 29, 1, false, 0), // 和歌山県
  KoukouMei('浜崎農林', 29, 1, false, 1), // 和歌山県
  KoukouMei('花咲学園', 29, 0, false, 0), // 和歌山県
  KoukouMei('鷹野西', 30, 2, false, 1), // 鳥取県
  KoukouMei('緑風学院', 30, 2, false, 1), // 鳥取県
  KoukouMei('河合商業', 30, 1, false, 1), // 鳥取県
  KoukouMei('永田中央', 30, 1, false, 1), // 鳥取県
  KoukouMei('今村西', 30, 0, false, 1), // 鳥取県
  KoukouMei('神楽学院', 31, 2, false, 1), // 島根県
  KoukouMei('荒波学園', 31, 2, true, 1), // 島根県
  KoukouMei('桜山学園', 31, 1, false, 1), // 島根県
  KoukouMei('岡田南', 31, 1, false, 0), // 島根県
  KoukouMei('谷川東', 31, 0, false, 1), // 島根県
  KoukouMei('白桃学院', 32, 3, false, 0, shoukai: '晴れの国の名門。トラックのスピード練習に力を入れ、切れのある走りを身につける。'), // 岡山県
  KoukouMei('晴天学園', 32, 2, false, 1), // 岡山県
  KoukouMei('福田南', 32, 1, false, 0), // 岡山県
  KoukouMei('陽光学園', 32, 1, false, 1), // 岡山県
  KoukouMei('沢井第二', 32, 0, false, 1), // 岡山県
  KoukouMei('折鶴学院', 33, 3, false, 0, shoukai: '一羽ずつ心を込めて折る折り鶴のように、一人ひとりを丁寧に育てる。切れ味のあるスパートが武器。'), // 広島県
  KoukouMei('島風学院', 33, 2, false, 1), // 広島県
  KoukouMei('松葉学院', 33, 1, false, 1), // 広島県
  KoukouMei('谷本工業', 33, 1, false, 2), // 広島県
  KoukouMei('白滝学院', 33, 0, false, 2), // 広島県
  KoukouMei('山霧館', 34, 2, false, 2), // 山口県
  KoukouMei('海原学院', 34, 2, false, 0), // 山口県
  KoukouMei('浅田北', 34, 1, false, 1), // 山口県
  KoukouMei('岡本中央', 34, 1, false, 0), // 山口県
  KoukouMei('土井工業', 34, 0, false, 1), // 山口県
  KoukouMei('渦潮学舎', 35, 2, false, 2), // 徳島県
  KoukouMei('藍染学園', 35, 2, false, 1), // 徳島県
  KoukouMei('北野工業', 35, 1, false, 1), // 徳島県
  KoukouMei('宮内第二', 35, 1, false, 1), // 徳島県
  KoukouMei('桐島', 35, 0, false, 1), // 徳島県
  KoukouMei('池内商業', 36, 2, false, 1), // 香川県
  KoukouMei('雲海学園', 36, 2, false, 2), // 香川県
  KoukouMei('細川第二', 36, 1, false, 2), // 香川県
  KoukouMei('杉谷第二', 36, 1, false, 1), // 香川県
  KoukouMei('戸川東', 36, 0, false, 0), // 香川県
  KoukouMei('潮流実業', 37, 3, false, 1, shoukai: '瀬戸内の潮の流れのように、途切れないたすきリレーを掲げる名門。粘り強い走りが持ち味。'), // 愛媛県
  KoukouMei('谷風学園', 37, 2, false, 2), // 愛媛県
  KoukouMei('黒沢中央', 37, 1, false, 2), // 愛媛県
  KoukouMei('小森北', 37, 1, false, 0), // 愛媛県
  KoukouMei('谷田第一', 37, 0, false, 1), // 愛媛県
  KoukouMei('山嵐学園', 38, 3, false, 2, shoukai: '山から吹き下ろす風のように、下り坂で一気に加速する。四国の山道で鍛えた脚が自慢。'), // 高知県
  KoukouMei('青波学院', 38, 2, false, 0), // 高知県
  KoukouMei('津田東', 38, 1, false, 1), // 高知県
  KoukouMei('桐野中央', 38, 1, false, 1), // 高知県
  KoukouMei('奥山', 38, 0, false, 2), // 高知県
  KoukouMei('山笠義塾', 39, 2, false, 1), // 福岡県
  KoukouMei('菅原北', 39, 2, false, 1), // 福岡県
  KoukouMei('野崎商業', 39, 1, false, 2), // 福岡県
  KoukouMei('小島西', 39, 1, false, 0), // 福岡県
  KoukouMei('石坂実業', 39, 0, false, 2), // 福岡県
  KoukouMei('光輝学舎', 40, 3, false, 1, shoukai: '歴史ある学舎で文武両道を掲げる名門。地道な走り込みで、どの区間も安定して走る。'), // 佐賀県
  KoukouMei('清光館', 40, 2, false, 1), // 佐賀県
  KoukouMei('宮坂', 40, 1, false, 1), // 佐賀県
  KoukouMei('栄陽館', 40, 1, false, 1), // 佐賀県
  KoukouMei('長坂', 40, 0, false, 1), // 佐賀県
  KoukouMei('潮騒実業', 41, 3, false, 1, shoukai: '坂の多い港町の名門。潮騒を聞きながら走る朝練が名物で、たすきへの思いの強さが自慢。'), // 長崎県
  KoukouMei('清英学舎', 41, 2, false, 1), // 長崎県
  KoukouMei('中里農林', 41, 1, false, 2), // 長崎県
  KoukouMei('里見農林', 41, 1, false, 1), // 長崎県
  KoukouMei('春陽学院', 41, 0, false, 1), // 長崎県
  KoukouMei('草原義塾', 42, 3, true, 1, shoukai: '広い草原を望む高台で走り込む名門。留学生と日本人の選手が、互いに刺激し合って力を伸ばす。'), // 熊本県
  KoukouMei('湧水学舎', 42, 2, false, 1), // 熊本県
  KoukouMei('緑川学院', 42, 1, false, 1), // 熊本県
  KoukouMei('矢野中央', 42, 1, false, 1), // 熊本県
  KoukouMei('花畑学舎', 42, 0, false, 1), // 熊本県
  KoukouMei('誠風館', 43, 3, false, 0, shoukai: '湯けむりの町の名門。誠実に練習を積み重ね、トラックで磨いたスピードを駅伝でも生かす。'), // 大分県
  KoukouMei('湯煙学院', 43, 2, false, 2), // 大分県
  KoukouMei('杉村', 43, 1, false, 1), // 大分県
  KoukouMei('星見義塾', 43, 1, false, 1), // 大分県
  KoukouMei('柳島東', 43, 0, false, 1), // 大分県
  KoukouMei('日輪学園', 44, 3, false, 1, shoukai: '温暖な気候を生かし、冬でも走り込みを欠かさない南国の名門。練習量では負けないのが自慢。'), // 宮崎県
  KoukouMei('南星館', 44, 2, false, 1), // 宮崎県
  KoukouMei('藤坂商業', 44, 1, false, 2), // 宮崎県
  KoukouMei('花見学院', 44, 1, false, 0), // 宮崎県
  KoukouMei('秀星学舎', 44, 0, false, 2), // 宮崎県
  KoukouMei('南浜商業', 45, 2, false, 0), // 鹿児島県
  KoukouMei('鹿谷北', 45, 2, true, 1), // 鹿児島県
  KoukouMei('黒木商業', 45, 1, false, 0), // 鹿児島県
  KoukouMei('宮園総合', 45, 1, false, 0), // 鹿児島県
  KoukouMei('丸山西', 45, 0, false, 2), // 鹿児島県
  KoukouMei('若夏学園', 46, 2, false, 1), // 沖縄県
  KoukouMei('星砂実業', 46, 2, false, 0), // 沖縄県
  KoukouMei('栗川工業', 46, 1, false, 1), // 沖縄県
  KoukouMei('仲村農林', 46, 1, false, 0), // 沖縄県
  KoukouMei('比嘉工業', 46, 0, false, 2), // 沖縄県
];
