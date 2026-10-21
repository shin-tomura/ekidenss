// 情報集約パネル(2.0.6で「区間終了時点の位置関係」として作り、2.0.7で名前を変えた)
// ・2.0.7から、区間を選ぶところの一番左に「スタート」を置く(1区のスタートの前の並び。出場校を大学のID順に
//   並べ、学連選抜は最後。距離はみな0で、順位・順位の変化・シード権ライン・右の括弧は出さない)。
//   大学の四角を押すと、帯に「大学名　目標○位」と1区を走る選手(区間配置確認のカードを開いたときと同じ中身)を
//   出し、もう一度押すと閉じる。1区の指示の画面(mode 350の1区)にもカードを置き、そこではスタートだけを出す。
// ・2.0.7から、区間は「‹」「›」で1つずつ、真ん中を押して出る一覧で好きな区間に切り替える(区間が多くても1行)。
// ・2.0.8から、区間を選ぶ行の右の黄色のボタンを押すたびに、「位置」(道の位置関係)→「通過」(通過順位速報)→
//   「個人」(個人順位速報)→「位置」と表示を切り替える。通過と個人は、今の速報の画面を、上のバーと下の「前・次」を
//   外して入れたもの(Modal_tuukajuni.dart・Modal_kukanresult350.dart(レースの途中)・Modal_kukanresult.dart
//   (結果画面)の umekomi)で、区間はパネルで選んだ区間。スタートでは、まだないことを出す。
//   通過と個人のときは、倍率の行を隠し、押した大学の帯は閉じる。覚えない(開いたときは「位置」)。
//   スタートしかないとき(1区の指示の画面)は、ボタンを出さない。
// ・2.0.9から、切り替えボタンの4つ目に「配置」(区間配置確認)を足した(位置 → 通過 → 個人 → 配置 → 位置。
//   スタートしかないとき(1区の指示の画面)は、位置 → 配置 → 位置)。区間配置確認の画面を、上のバー(共有のボタンも)・
//   大学を選ぶ行・下の「戻る」を外して入れたもの(Modal_kukanhaiti2.dart の umekomi)。配置のときは、区間を選ぶ欄が
//   大学を選ぶ欄(「‹」「›」は端まで行くと反対の端に回る。一覧は出場校のID順で、学連選抜がいる年は最後に学連選抜)に
//   入れ替わる。最初は自分の大学(学連選抜の監督の年は学連選抜。自分の大学が出ていない年は、ID順の最初の大学)で、
//   画面を閉じるまで選んだ大学を覚える。大学名は1行に収め、入りきらないところは「…」で省く。
// ・2.1.1から、切り替えボタンの5つ目に「推移」を足した(位置 → 通過 → 個人 → 配置 → 推移 → 位置)。
//   中継所ごとの位置の図を、区間を5つに分けてつなぎ、コマ送りで見せる(_suiiKoma)。区間の中は、どの大学もその区間を
//   同じペースで走ったとみなし、各地点を通ったときのタイム差を、位置の図と同じく区間の平均の速さ(前の区間の速さから
//   この区間の速さへ少しずつ変える)で距離にする。区間の終わりで、位置の図とぴったり同じになる。
//   ・1区は、飛び出した選手と集団の記録をもとにした演出にする(_IkkuEnshutsu・_ikkuJikoku。2.1.1の開発中は、
//     途中の動きを作れないので1区終了時点から再生していた)。スタートから、飛び出した選手は区間の4割まで集団の前で
//     差を広げ(成功は集団のタイムの1%、失敗は0.5%)、そこからは1区のタイムに向かう。飛び出さなかった選手は、
//     集団のペース(集団を引っ張った選手のペース。ikku_pace.dart の記録)で一緒に進み、最後の4分の1でばらけて
//     1区のタイムに向かう。集団のペースが速すぎた選手(1区のタイムが集団のタイムより3%以上遅い)は、半分から遅れ始める。
//     集団の中は同じタイムなので、同じ順位にし、並びは集団を引っ張った大学を先頭に大学のID順(結果が先に分からないように)。
//     集団のペースの記録がない(別の大会の記録など)ときは、今まで通り1区終了時点から(2区から)にする。
//     推移は、1区が終わったら(1区の演出ができないときは2区が終わったら)順番に入れる
//   ・地点(「○km地点」)は出さない(区間の中の動きは推定なので、作り物だと分かるように)。
//     区間名と区間の距離と、数字のない進み具合の丸だけを出す
//   ・コマ送り(2.1.1の開発中は、画面の書き換えに合わせてなめらかに動かしていたが、電池を使うのでやめた):
//     区間を5つに分け、1コマずつ図を切り替える(すべらせない)。区間の始め(中継所)は0コマ目で、前の区間の
//     5コマ目と同じ図なので、続けて再生するときと◀▶では1回にまとめ、中継所のコマは2倍止まる。
//     1コマはふつう1秒(ゆっくり2秒・はやい0.5秒。区間の距離には関係ない)。再生は1コマごとに1回だけ動くタイマーで進め、
//     コマのあいだは何も計算・描画しない。◀▶(「1コマ」)は止めてから1コマ動かし、区間をまたぐ。
//     進み具合は5つの丸(区間の始めは全部白、中継所は全部黒)。選んでいる区間から、終わった区間の最後まで続けて再生する。
//     「最初から」を押すと、どの区間を見ていても最初(1区の演出ができればスタート、できなければ1区終了時点)に戻り、
//     最後まで通しで再生する
//   ・推移の画面では、再生の前も、止めたときも、再生し終えたあとも、いつも推移の描き方(途中を省略しない)にする
//     (2.1.1の開発中は、区間の終わり(進み具合が1)だけ位置の図をそのまま使っていたので、再生し終えた瞬間に
//     途中が省略されて道が縮み、焦点の大学が画面の外に出ていた)
//   ・焦点は、大学(その大学を追う)か順位(その順位にいる大学を追う。シード権の最後の順位には「(シード権ライン)」)。
//     最初は自分の大学(学連選抜の監督の年は学連選抜。出ていなければ1位)。焦点の大学は、道が見えている高さの
//     上から3分の1に来るように、コマを変えるたびに道を動かす(指で道を動かすと再生を止める)。焦点の大学は水色の枠
//   ・大学の四角を押すと、その大学に焦点を移す(下の帯は出さない)。倍率は「−」「＋」で、おまかせのときは×4。
//     再生中は途中の省略(点線)をしない(省略が出たり消えたりして道が跳ねないように)
//   ・四角の中の順位は、そのコマの時点の順位(その地点を通った順)。順位の変化の出し方は、定数 suiiHendouKata で
//     切り替える(どの形のコードも残してある。四角の欄の幅と説明書の文は、この値に合わせて変わる)。
//     ・nukisuu(今の形): 前の中継所からこれまでに抜いた大学の数「↑3」(緑)と抜かれた数「↓1」(赤)。両方あれば「↑3↓1」。
//       区間の中は同じペースとみなすので、2校の前後が入れ替わるのは1つの区間で多くても1回で、数は増えるだけ
//       (中継所での前後と今のコマの前後を比べて数える。同じタイムは数えない)。学連選抜は数えない(順位に数えないので、
//       抜いただけのときは「↑の数=順位の上がった数」になる)。学連選抜の四角には、学連選抜が抜いた・抜かれた大学の数
//     ・sashihiki: 前の中継所からの順位の変化の数「↑2」「↓3」(位置と同じ数え方)
//     ・yajirushi: 矢印だけ「↑」「↓」(2.1.1の開発中の形)
//     どの形も、変わらなければ何も出さず、1区の演出のあいだは出さない。位置は今まで通り「↑2」「↓3」「→」
//   ・推移から位置に切り替えると、推移で見ていた区間を出す。覚えない(開いたときは「位置」)
// ・2.0.8〜2.0.9は、おまかせのときに「おまかせ」をもう一度押すと「おまかせ ↔」(幅に合わせる)になり、道が横幅に
//   収まるように道の上の文字を6割まで小さくしていた。2.1.0で、集団の1行に画面の幅に入るだけ並べるようになり、
//   横にはみ出すのは四角1つと右の差だけで画面の幅を超えるときだけになったので、なくした(そのときは横にスクロールする)。
// レースの途中の区間ごとの画面(mode 350)と、結果画面(10月駅伝・11月駅伝・正月駅伝・カスタム駅伝)の、
// 区間ごとのタイム分布と1枚にまとめたカード(KukanBunsekiCard。右半分の「位置関係」)から開く。
// ・幅のある道の帯に、大学名を四角で囲んで並べ、1位からの距離を縮尺どおりの間隔で出す。
//   四角の中の大学名は、最後の「大」を省く(下の帯の文は省かない)。学連選抜は四角の中では「OP学連」。
//   2.1.0から、四角の中を順位・大学名・順位の変化の欄に分ける。順位と順位の変化の欄は区間の中でそろえ、
//   大学名の欄は名前の長さにする(4文字分まで。それより長い名前は横だけ縮め、5割まで縮めても入らなければ
//   最後を「…」で省く。2.1.0の開発中は、どの四角も同じ幅(大学名は2文字分)にしていたが、4文字の名前を
//   2文字分に縮めると読みにくかったので、名前の長さに合わせた)。
//   大学名の後ろに、前の区間の終了時点からの順位の変化を「↑2」(緑)「↓3」(赤)「→」(灰色)で付ける
//   (1区は付けない。学連選抜は通過順位相当で比べる。下の帯にも「5位(↑3)」の形で出す)。
// ・集団(2.1.0から): 前の大学との差が1秒以内(右の括弧と同じ切り捨ての秒。「並走」か「1秒」)なら、
//   同じ集団としてつなげる(長さの上限はなし。拡大・縮小しても変わらない)。シード権ラインと詰めた間では分ける。
//   (2.0.9までは、画面の上で四角1つ分より近い大学をつなげていたので、倍率が小さいと100m以上離れた大学も
//   同じ枠に入り、集団走のように見えていた)
//   集団の中は、先頭と同じ秒の大学を1行目に横に並べ、1秒遅れるごとに次の行にし、秒が変わった行の右に
//   「+1秒」を出す(同じ秒で入りきらずに折り返した行には出さない)。
//   1行には、「四角の行 + 右の括弧と差の文」が画面の幅に入るだけ並べ、入らなくなったら次の行に折り返す
//   (数の上限はなし。四角の幅は名前で違うので、行ごとに決める。入る幅(_gyouJougen)は、右の差の文を
//   パネルで見られる全部の区間で一番長い文にして決めるので、区間を切り替えても同じ並びなら同じ折り返し。
//   2.1.0の開発中は、3校までの数(3→2→1)をパネル全体で決めていた)。
//   集団でない大学は1校ずつ縦に並べ、どの間にも右の括弧と差を出す。
//   集団の一番上の行は、前の大学(前が集団なら、その一番下の行)から、間の距離ぶん下に置き、
//   集団のあとの大学は、集団の一番下の行を起点にして、集団の最後の大学との間の距離ぶん下に置く。
//   四角が重なるほど近いときは、重ならないところまで下に広げて置く(印は付けない。右の数字が本当の差)。
//   2校以上の集団は、四角にぴったり合わせた薄い枠で囲む。集団どうしは、枠がくっつかないよう10px以上空ける。
//   2.1.0から、四角を行ごとに道の左右の真ん中に置く(集団は隊列のような形になる。「+1秒」は四角の右に出し、
//   枠は道の真ん中を軸に左右同じ幅で囲む。行が道より広いときは、今まで通り左から並べて横にスクロール)。
// ・画面の説明の文は短くし(「○区終了時点のタイム差を、区間の平均の速さで距離に換算した位置関係の図です」
//   と、括弧・色・押したときのこと)、おまかせと集団の説明は説明書に書く。
// ・道の右に、前の大学(集団)との間を示す括弧を引き、その真ん中に間の距離と秒差を出す。
//   2.1.0から、距離と秒差を2行にし(「90m」の下に「16秒」)、文字を少し小さく(12→11)して幅を抑えた。
//   文字を大きくしても文が括弧からずれないように、集団どうしの間は2行の文が収まる高さより狭くしない。
//   括弧は、前の集団の一番下の行の真ん中から、次の集団の一番上の行の真ん中まで。集団の中の間は出さない。
//   (1位との差を出していたが、隣どうしの間が縮尺どおりなので、間を出すほうが分かりやすいため、2.0.6の開発中に変えた)
// ・四角と間の文は折り返さず、道と四角と間の文の部分だけを横にもスクロールできるようにする
//   (文字を大きくしても、文の長さで行がずれて、距離と位置が合わなくならないように)。
// ・大学の四角を押すと、その大学の順位・1位との差・前の大学(1位は次の大学)との差を、
//   画面の下に固定した帯に出す。
//   もう一度押すと、帯の中に、その区間を走った選手の説明文(個人順位速報の「説明文」と同じ文)も出し、
//   3回目で、説明文の代わりに次の区間を走る選手(区間配置確認のカードを開いたときと同じ中身。
//   senshu_haichi_panel.dart の部品)を出し、4回目で閉じる。最終区など次の区間の選手がいなければ3回目で閉じる。
//   2.1.0から、2回目は説明文の下に走った選手の、3回目は次の区間を走る選手の、持ちタイムの表と能力(1行に1つ)を
//   同じ並びで出す(_kirokuToNouryoku。カードの能力の行は、下の能力に全部入るので出さない)。
//   開いたまま、ほかの四角を押すと、同じ段のままその大学に切り替える。
//   帯の一番上の行(差の基準と閉じる「×」)は固定し、その下は、まとめて帯の中でスクロールする。
//   同じ段のまま、ほかの大学の四角を押したときは、帯のスクロールの位置を保つ(次の区間の選手は持ちタイムの表、
//   説明文は本文の始まりが、切り替える前と同じ高さに来るようにする。測れなければスクロールの量をそのまま保つ)。
//   同じ大学で段が進んだときと、区間を切り替えたときは、先頭に戻す。
//   帯が伸びて押した四角が隠れるときは、道を動かして見えるようにする(2.0.7)。
//   説明文の上の行(走った選手)にも、区間配置確認と同じ「詳細」を置き、選手の詳細の画面を開けるようにする。
// ・下の帯の一番上の「差の基準」で、1位との差の代わりに、押した大学それぞれの目標順位との差を出せる(2.0.7)。
//   目標より下なら目標の順位の大学との差(「目標3位(東湊大)と120m +22秒」)、目標以内なら目標の1つ下の大学との
//   差(「目標3位以内　4位の白鷺大に250m 45秒のリード」。区間ごとの画面の「○位との差」と同じ考え)。
//   学連選抜は、レースの計算と同じ学連選抜の目標(監督をしていれば決めた順位、ほかは10位)で、順位は相当で比べる。
//   目標順位は今の値(正月駅伝で復路の目標を決め直したあとは、往路の区間も決め直したあとの目標で出す)。
//   選んだ基準は、大学や区間を替えてもそのままで、覚えない(画面を閉じたらトップに戻る)。
// ・区間の切り替えと、表示の倍率のボタン・縮尺の棒は、画面の上に固定する(どちらも折り返す)。
//   固定の部分は、上のバーを除いた高さの3割までで、超えるときは固定の部分の中だけでスクロールする。
// ・押した大学の帯は、道の下(画面の一番下)に置き、上のバーを除いた高さの4割5分までにする。
//   道にはいつも4分の1以上を残す(小さいスマホで文字を大きくしても、道が消えて四角を押せなくならないように。
//   2.0.6は、固定の部分が画面の高さの4割まで、帯は「戻る」の上の固定で、高さを抑えていなかった。2.0.7)
// ・画面の一番下の「戻る」は、2.0.7でなくした(道を広くするため。左上の「←」と、Androidの戻る操作で閉じる)。
// ・距離は「1位が区間を走り終えたとき、ほかの大学がどれだけ後ろにいるか」を、その区間の出場校の
//   区間タイムの平均から出した速さ(全員で同じ。学連選抜は平均に入れない)で、タイム差から換算したもの。
//   速さを全員で1つにするので、距離はタイム差に比例し、順位と位置の並びが逆にならない
//   (ゲームとしての見せ方。1位が着いた時点か最後の大学が着いた時点か、などは考えない)。
// ・1区から終わった区間まで切り替えられる(覚えない。開くたびに一番あとの区間)。
// ・前の大学との間のうち、その倍率で描くと、道が見えている高さより長くなる間だけを詰めて(_tsumeAida)、
//   道に切れ目の点線を引き、右の括弧を点線にする(拡大しすぎて、何もない道を延々とスクロールしないように。
//   2.0.9までは「(詰めています)」を添えていた。2.1.0の開発中に「(途中を省略)」にしたが、幅を取るので
//   添え書きはなくし、点線で示す)。
//   (2.0.6〜2.1.0の開発中は、飛び抜けて大きい間(その区間の間の中央値の4倍以上。大きい順に多くて3か所)も
//   詰めていた。大きく遅れた大学に引っぱられて、おまかせで先頭のほうが縮こまらないようにするためだったが、
//   接戦の区間では100mほどの間まで詰められて気になり、おまかせに×4の下限ができて役目もほぼなくなったので、
//   2.1.0の開発中に、画面の高さより長い間だけにした。最初は「画面で144pxを超えたら」詰めていたが、
//   出場校の少ない大会や差の開いた区間で、ほとんどの間が詰められて位置関係がつかめなかった)
//   道が見えている高さは、上のバーと、上に固定する部分(区間の切り替えと倍率のボタン)と区切りの線を除いた高さ
//   (_koteiKey で固定する部分の高さを描いたあとに測る。押した大学の帯の分は引かない(押すたびに省略が変わって
//   道が動かないように)。2.1.0の開発中まで、機械の画面全体の高さを使っていた)
// ・表示の倍率(1mあたりの高さ)は「−」「＋」で6段階に変えられる(文字の大きさは変わらない)。
//   開いたときは「おまかせ」(区間ごとに、詰めた間を除いた1位から最後尾までの長さが、道が見えている高さの
//   およそ2つ分に収まる一番大きい倍率。詰める間は倍率ごとに違うので、倍率ごとに数え直す)。
//   2.1.0から、おまかせは×4より小さくしない(_omakaseSaitei。差の開いた区間で×1/2などになると、100mの差も
//   10mの差も四角が重ならない一番小さい間隔になり、同じに見えていたため。開発中は×2にしたが、四角どうしの
//   一番小さい間隔(約38px)が約48mになり、80mと10mがほとんど同じに見えたので×4にした(約24m))。
//   縦が長くなるので、道の右端につまんで動かせるスクロールバーを出した(2.1.0の開発中は、説明の「オレンジの枠」の
//   行を押すと自分の大学まで動くようにもしたが、何が起きるか分かりにくく、ボタンにすると固定の行が増えるのでなくした)。
//   「−」「＋」を押すとおまかせが外れ、区間を切り替えてもその倍率のまま。
//   覚えない(画面を閉じたらおまかせに戻る)。倍率のボタンの横に縮尺の棒を出す。
// ・11月駅伝は8位、正月駅伝は10位の大学のすぐ下にシード権ラインを引く(10月駅伝とカスタム駅伝はなし。
//   学連選抜が10位と11位の間にいても、学連選抜はラインの下。2.1.0で直した)。
//   ラインをまたいでは集団にしない。詰めた間のあとも新しい集団にする。
// ・四角の見た目: 自分の大学はオレンジの枠(文字と塗りはほかの大学と同じ)、1位は太い白の枠、学連選抜(正月駅伝のオープン参加)は
//   点線の枠(学連選抜の監督をした年はオレンジの点線)。学連選抜は順位とシード権ラインに数えない。
// ・距離は1kmまでは10m単位、1km以上は「1.2km」。秒は画面と同じく切り捨ててから引き(saByou)、
//   距離はその秒から出す。間が0秒なら「並走」。四角を押したときの下の帯では、1位との差
//   (「180m +33秒」。0秒なら「トップと並走」)と前の大学との差を出す。
// ・結果は記事と同じ EkidenKekka(kiji_kekka.dart)から作る。レースの途中は1区から終わった区間まで。
//   新しく保存するものはない。作れなければカードを出さない。
// ・2.0.6の開発中に、点と名前の行の形から四角の形に変え、2枚あったカード(タイム分布と位置関係)を
//   見出しだけの1枚にした。

import 'dart:async' show Timer; // 推移のコマ送りの再生(2.1.1)
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/kansuu/shushou.dart'
    show shushouShirushi, shushouKaIma; // 主将の印(個人順位速報・区間配置確認と同じ。2.0.7)
import 'package:ekiden/kansuu/konki_best.dart'; // 今季ベスト(区間配置確認と同じ設定。2.0.7)
import 'package:ekiden/screens/shushou_iro.dart'; // 主将を示す色(区間配置確認と同じ。2.0.7)
import 'package:ekiden/screens/senshu_haichi_panel.dart'; // 区間配置確認のカードの部品(2.0.7)
import 'package:ekiden/screens/Modal_tuukajuni.dart'
    show ModalKukanResultListViewPass; // 通過順位速報(パネルの中に入れる。2.0.8)
import 'package:ekiden/screens/Modal_kukanresult350.dart'
    show ModalKukanResultListView350; // 個人順位速報(レースの途中。2.0.8)
import 'package:ekiden/screens/Modal_kukanresult.dart'
    show ModalKukanResultListView; // 個人順位速報(結果画面。2.0.8)
import 'package:ekiden/screens/Modal_kukanhaiti2.dart'
    show ModalKukanHaitiView, kukanHaitiGakurenId; // 区間配置確認(パネルの中に入れる。2.0.9)
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_kekka.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';
import 'package:ekiden/kansuu/gakuren_kantoku.dart';
import 'package:ekiden/kansuu/ikku_pace.dart'
    show IkkuPaceKekka, ikkuPaceKekkaYomu; // 推移の1区の演出に使う集団のペースの記録(2.1.1)
import 'package:ekiden/screens/Modal_kukanTimeBunpu.dart'
    show KukanBunpuYomikomi, kukanBunpuYomu, kukanBunpuGamenHiraku;

/// 表示の倍率の段階(1mあたりの高さ(px))と名前(×1は、最初に作ったときの決め打ちの倍率)
const List<double> _bairitsu = [0.1, 0.2, 0.4, 0.8, 1.6, 3.2];
const List<String> _bairitsuMei = ['×1/4', '×1/2', '×1', '×2', '×4', '×8'];

/// おまかせの倍率: 1位から最後尾までが、画面の高さのこの倍に収まる一番大きい倍率
const double _omakaseGamen = 2.0;

/// 推移(2.1.1)の、1つの区間のコマの数(区間を5つに分ける。0コマ目が区間の始め、5コマ目が中継所)
const int _suiiKomaSuu = 5;

/// 推移の速さ(ゆっくり・ふつう・はやい)の、1コマの時間(ミリ秒)と名前。中継所のコマはこの2倍止まる
const List<int> _suiiKomaMs = [2000, 1000, 500];
const List<String> _suiiHayasaMei = ['ゆっくり', 'ふつう', 'はやい'];

/// 推移で、焦点の大学を置く高さ(道が見えている高さの、上からこの割合のところ)
const double _suiiShotenTakasa = 1 / 3;

/// 推移(2.1.1)の、大学の四角の中の順位の変化の出し方(開発者が切り替える。プレイヤーの設定ではない。
/// 四角の欄の幅と説明書の文(setsumeisho_text.dart)は、この値に合わせて変わる。切り替えるときは変更履歴を直す)
enum SuiiHendouKata {
  /// 前の中継所からこれまでに抜いた大学の数「↑3」と、抜かれた数「↓1」(両方あれば「↑3↓1」)
  nukisuu,

  /// 前の中継所からの順位の変化の数「↑2」「↓3」(位置と同じ数え方)
  sashihiki,

  /// 矢印だけ「↑」「↓」
  yajirushi,
}

/// 今の推移の順位の変化の出し方
const SuiiHendouKata suiiHendouKata = SuiiHendouKata.nukisuu;

/// 推移の1区の演出(2.1.1): 集団がばらけ始めるところ(区間の最後の4分の1)
const double _ikkuBarakeIchi = 0.75;

/// 集団のペースが速すぎた選手(1区のタイムが集団のタイムのこの倍より遅い)と、遅れ始めるところ(区間の半分)
const double _ikkuShissokuWariai = 1.03;
const double _ikkuShissokuIchi = 0.5;

/// 飛び出した選手の差が一番開くところ(区間の4割)と、その差(集団のタイムに対する割合。成功・失敗)
const double _ikkuTobidashiIchi = 0.4;
const double _ikkuTobidashiSeikou = 0.01;
const double _ikkuTobidashiShippai = 0.005;

/// おまかせの倍率の下限(_bairitsu の番号。4は×4。四角どうしの一番小さい間隔が約24mになり、
/// 数十mの差が見分けられる。2.1.0。開発中は3(×2)だった)
const int _omakaseSaitei = 4;

/// 詰めたところの高さ(px)
const double _tsumePx = 52;

/// 道の帯の右に置く括弧と差の文の、文以外の幅(括弧までのすきま6・括弧から文まで14・文の右の余白8)
/// (2.1.0から、道の帯は画面の幅からこの幅と差の文の幅を引いた残り全部にする。2.0.9までは画面の幅の6割と
/// 決めていたが、差の文を2行にして細くしたら、右に大きな余白が残ったため。四角の行のほうが広いときは
/// 四角に合わせ、はみ出したぶんは横にスクロールする)
const double _migiYohaku = 6.0 + 14.0 + 8.0;

/// 前の大学との差がこの秒以内なら、同じ集団にする(右の括弧と同じ切り捨ての秒。2.1.0)
const int _shuudanByou = 1;

/// 詰めた間の括弧の文に添える言葉

/// 四角どうし・行どうしのすきま
const double _sukima = 4;

/// 集団(1校だけのときも)どうしの最小のすきま(枠どうしがくっつかないように)
const double _shuudanSukima = 10;

/// 四角の左端(集団の枠の内側の余白のぶん、道の端から空ける)
const double _hakoHidari = 8;

/// 集団の枠の、四角のまわりの余白
const double _wakuYohaku = 4;

/// 四角の中の余白(横・縦)
const double _hakoYoko = 6;
const double _hakoTate = 3;

/// 四角の中の大学名の欄の上限の文字数(欄は名前の長さにし、これより長い名前は横に縮める。2.1.0)
const int _meiMojisuu = 4;

/// 大学名を横に縮める下限(これより縮めないと入らないときは、最後を「…」で省く。2.1.0)
const double _meiChijimiSaishou = 0.5;

/// 四角の中の、順位と大学名のすきま・大学名と順位の変化のすきま(2.1.0)
const double _juniSukima = 4;
const double _hendouSukima = 3;

/// 四角の中の文字(順位と「OP」・大学名・順位の変化。順位の変化の色は変化ごとに付ける)
/// (順位は2.1.1から、白い太字で少し大きくした(それまでは薄い灰色の11.5)。推移でコマごとに変わる順位が目に入るように。
///  位置も同じにし、学連選抜の「OP」も同じ字)
const TextStyle _juniStyle = TextStyle(
  color: HENSUU.textcolor,
  fontSize: 14,
  fontWeight: FontWeight.bold,
);
const TextStyle _meiStyle = TextStyle(color: HENSUU.textcolor, fontSize: 13);
const TextStyle _hendouStyle = TextStyle(fontSize: 12);

/// 区間の四角の中の欄の幅と文の高さ(2.1.0。順位と順位の変化の欄は区間の中でそろえる。
/// 大学名の欄は名前の長さで、ここには上限を持つ)
class _HakoHaba {
  /// 順位の欄(学連選抜の「OP」も。なければ0)
  final double juni;

  /// 大学名の欄の上限(_meiMojisuu 文字分)
  final double mei;

  /// 順位の変化の欄(1区とスタートは0)
  final double hendou;

  /// 文の高さ
  final double takasa;

  const _HakoHaba(this.juni, this.mei, this.hendou, this.takasa);

  /// 大学名の欄が[meiHaba]のときの、中身の幅(欄とすきまの合計)
  double naka(double meiHaba) =>
      juni + (juni > 0 ? _juniSukima : 0) + meiHaba + (hendou > 0 ? _hendouSukima + hendou : 0);
}

/// 四角の枠の太さの最大(四角の大きさを決めるときに、これだけ見込む)
const double _wakuSaidai = 2;

/// 道の帯の色
const Color _michiIro = Color(0xFF1C1C1C);

/// カードと位置関係の色
const Color _iro = Colors.lightBlueAccent;

/// 自分の大学の色(区間ごとのタイム分布と同じ)
const Color _jibunIro = Colors.orangeAccent;

/// 道の中の四角に出す大学名(最後の「大」を省く。「東湊大」→「東湊」。省くと空になるときはそのまま)
String _michiMei(String mei) =>
    (mei.length > 1 && mei.endsWith('大')) ? mei.substring(0, mei.length - 1) : mei;

/// 道の右の括弧の秒差の文(1分未満は「40秒」、1分以上は「3'40"」。2.1.0。
/// 幅を抑えるため、記事などの「3分40秒」(saMoji)より短い、今季タイム一覧表のタイムと同じ書き方にする。
/// 四角を押したときの下の帯は、場所に余裕があるので「3分40秒」のまま)
String _aidaByouMoji(int sa) {
  final int s = sa.abs();
  if (s < 60) return '$s秒';
  return '${s ~/ 60}\'${(s % 60).toString().padLeft(2, '0')}"';
}

/// 距離の文(「180m」「1.2km」。1kmまでは10m単位)
String _kyoriMoji(double m) {
  final int r = (m / 10).round() * 10;
  if (r < 1000) return '${r}m';
  return '${(m / 1000).toStringAsFixed(1)}km';
}

/// 区間順位(個人順位速報と同じく大学データの区間順位。なければ結果から数えた順位。2.0.7)
int _kukanJuniYomu(EkidenUnivKekka x, int kk) {
  final List<int> kj = x.u.kukanjuni_taikai;
  if (kj.length > kk && kj[kk] >= 0 && kj[kk] != TEISUU.DEFAULTJUNI) return kj[kk];
  return x.kukanJuni[kk];
}

/// 大学1校分(学連選抜も)
class _IchiDaigaku {
  final String mei;

  /// 区間終了時点の累計タイム
  final double ruikei;

  /// 区間終了時点の順位(0が1位。学連選抜は-1)
  final int juni;

  /// 自分の大学か
  final bool jibun;

  /// 学連選抜(オープン参加)か
  final bool op;

  /// 前の区間の終了時点からの順位の変化(上げた数がプラス、下げた数がマイナス、同じなら0。
  /// 1区はnull。学連選抜は通過順位相当で比べる。2.0.6)
  final int? hendou;

  /// 学連選抜の通過順位相当(0が1位相当。大学はnull)
  final int? soutouJuni;

  /// その区間を走った選手(大学は senshu、学連選抜は gSenshu。分からなければnull。
  /// 四角を2回押したときの説明文に使う。2.0.7)
  final SenshuData? senshu;
  final Senshu_Gakuren_Data? gSenshu;

  /// 学連選抜の選手の所属大学の名前(大学はnull)
  final String? shozoku;

  /// 区間順位(0が1位。学連選抜は区間順位相当)
  final int? kukanJuni;

  /// 区間タイム
  final double? kukanTime;

  /// 次の区間を走る選手(大学は tsugiSenshu、学連選抜は tsugiGSenshu。最終区などはnull。
  /// 四角を3回押したときに、区間配置確認のカードを開いたときと同じ中身を出す。2.0.7)
  final SenshuData? tsugiSenshu;
  final Senshu_Gakuren_Data? tsugiGSenshu;

  const _IchiDaigaku(
    this.mei,
    this.ruikei,
    this.juni,
    this.jibun,
    this.op, {
    this.hendou,
    this.soutouJuni,
    this.senshu,
    this.gSenshu,
    this.shozoku,
    this.kukanJuni,
    this.kukanTime,
    this.tsugiSenshu,
    this.tsugiGSenshu,
    this.mokuhyou,
    this.univId,
    this.nuita,
    this.nukareta,
  });

  /// 目標順位(0が1位。学連選抜は学連選抜の目標。分からなければnull。差の基準を目標順位にしたときに使う。2.0.7)
  final int? mokuhyou;

  /// 大学id(学連選抜はnull。推移で、区間をまたいで同じ大学を見分けるのに使う。2.1.1)
  final int? univId;

  /// 推移で、前の中継所からこれまでに抜いた大学の数と、抜かれた大学の数(学連選抜は数えない。推移のほかはnull。2.1.1)
  final int? nuita;
  final int? nukareta;

  /// 抜いた数と抜かれた数を付けたもの(ほかはそのまま。2.1.1)
  _IchiDaigaku nukisuuTsuki(int nuitaKazu, int nukaretaKazu) => _IchiDaigaku(
    mei,
    ruikei,
    juni,
    jibun,
    op,
    hendou: hendou,
    soutouJuni: soutouJuni,
    senshu: senshu,
    gSenshu: gSenshu,
    shozoku: shozoku,
    kukanJuni: kukanJuni,
    kukanTime: kukanTime,
    tsugiSenshu: tsugiSenshu,
    tsugiGSenshu: tsugiGSenshu,
    mokuhyou: mokuhyou,
    univId: univId,
    nuita: nuitaKazu,
    nukareta: nukaretaKazu,
  );

  /// 次の区間を走る選手がいるか
  bool get tsugiAri => tsugiSenshu != null || tsugiGSenshu != null;

  /// 走った選手の詳細の画面を開くときの選手id(区間配置確認と同じ。分からなければnull。2.0.7)
  int? get shousaiId => senshu?.id ?? gSenshu?.id;

  /// 走った選手の説明文(個人順位速報の「説明文」と同じ。末尾の改行は省く。なければnull。2.0.7)
  String? get setsumei {
    final String? s = senshu?.string_racesetumei ?? gSenshu?.string_racesetumei;
    if (s == null) return null;
    final String t = s.trimRight();
    return t.isEmpty ? null : t;
  }

  /// 順位の変化の文(「↑2」「↓3」「→」。1区はnull)
  String? get hendouMoji {
    final int? h = hendou;
    if (h == null) return null;
    if (h > 0) return '↑$h';
    if (h < 0) return '↓${-h}';
    return '→';
  }
}

/// 区間1つ分の位置関係
class _IchiKukan {
  /// 区間(0が1区。-1はスタート。2.0.7)
  final int kk;

  /// 区間の平均の速さ(m/秒)
  final double hayasa;

  /// 累計タイムの順(学連選抜も入る)
  final List<_IchiDaigaku> narabi;

  /// 推移(2.1.1)で、区間の途中を作ったものか(中継所の図ではない。_suiiKoma)
  final bool suii;

  /// 推移で、四角の中の順位の変化の欄の幅を決める文(その区間で出うる一番広い文。区間の途中で欄の幅が
  /// 変わらないように。2.1.1)
  final List<String> hendouHabaMoji;

  _IchiKukan(
    this.kk,
    this.hayasa,
    this.narabi, {
    this.suii = false,
    this.hendouHabaMoji = const [],
  });

  /// 1位(学連選抜を除く)
  _IchiDaigaku get top => narabi.firstWhere((x) => !x.op, orElse: () => narabi.first);

  /// [x]の、1位との差(秒。画面と同じく切り捨ててから引く。1位より前の学連選抜はマイナス)
  int sa(_IchiDaigaku x) => saByou(x.ruikei, top.ruikei);

  /// 1kmあたりのタイム(秒)
  int get pace => hayasa > 0 ? (1000 / hayasa).round() : 0;

  /// 1位との差の文(距離が先。「トップ」「180m +33秒」「トップと並走」「トップより30m前 5秒」)
  String saBun(_IchiDaigaku x) {
    if (identical(x, top)) return 'トップ';
    final int s = sa(x);
    if (s == 0) return 'トップと並走';
    if (s < 0) return 'トップより${_kyoriMoji(-s * hayasa)}前 ${saMoji(s)}';
    return '${_kyoriMoji(s * hayasa)} +${saMoji(s)}';
  }

  /// [x]の目標順位との差の文(差の基準を目標順位にしたとき。2.0.7)
  /// 目標より下なら「目標3位(東湊大)と120m +22秒」、目標以内なら「目標3位以内　4位の白鷺大に250m 45秒のリード」。
  /// 学連選抜は順位相当で比べる(目標以内なら、押し出される目標の順位の大学とのリード)
  String mokuhyouBun(_IchiDaigaku x) {
    final int? t = x.mokuhyou;
    if (t == null || t < 0) return '目標順位なし';
    // 大学だけの順位の順(学連選抜は入れない。並びの番号が順位)
    final List<_IchiDaigaku> daigaku = [for (final _IchiDaigaku y in narabi) if (!y.op) y];
    _IchiDaigaku? juniNo(int j) => (j >= 0 && j < daigaku.length) ? daigaku[j] : null;
    // 目標以内のときの、目標の1つ下の大学とのリードの文
    String lead(_IchiDaigaku ushiro) {
      final int s = saByou(ushiro.ruikei, x.ruikei);
      return s <= 0 ? 'と並走' : 'に${_kyoriMoji(s * hayasa)} ${saMoji(s)}のリード';
    }

    final String soutou = x.op ? '相当' : '';
    final int jibunJuni = x.op ? (x.soutouJuni ?? 0) : x.juni;
    final _IchiDaigaku? mokuhyouDaigaku = juniNo(t);
    if (jibunJuni > t) {
      // 目標より下: 目標の順位の大学との差
      if (mokuhyouDaigaku == null) return '目標${t + 1}位$soutou';
      return '目標${t + 1}位$soutou(${mokuhyouDaigaku.mei})と${futatsuBun(x, mokuhyouDaigaku)}';
    }
    // 目標以内: 目標の1つ下の大学(学連選抜は、押し出される目標の順位の大学)とのリード
    final int ushiroJuni = x.op ? t : t + 1;
    final _IchiDaigaku? ushiro = juniNo(ushiroJuni);
    if (ushiro == null) return '目標${t + 1}位以内$soutou';
    return '目標${t + 1}位以内$soutou　${ushiroJuni + 1}位の${ushiro.mei}${lead(ushiro)}';
  }

  /// 2つの大学の間の文(道の右の括弧に出す。間なので「+」を付けない。0秒は「並走」)
  /// 2.1.0から、幅を抑えるため距離と秒差を2行にし(「90m」の下に「16秒」)、1分以上の秒差は
  /// 今季タイム一覧表のタイムと同じ「3'40"」の形にする(_aidaByouMoji)
  String aidaBun(_IchiDaigaku osoi, _IchiDaigaku hayai) {
    final int s = saByou(osoi.ruikei, hayai.ruikei);
    if (s <= 0) return '並走';
    return '${_kyoriMoji(s * hayasa)}\n${_aidaByouMoji(s)}';
  }

  /// 2つの大学の差の文(距離が先。「30m +5秒」。0秒は「並走」)
  String futatsuBun(_IchiDaigaku osoi, _IchiDaigaku hayai) {
    final int s = saByou(osoi.ruikei, hayai.ruikei);
    if (s <= 0) return '並走';
    return '${_kyoriMoji(s * hayasa)} +${saMoji(s)}';
  }

  /// 名前の行を押したときの、前の大学(1位は次の大学)との差の文
  String maeBun(int i) {
    if (i == 0) {
      if (narabi.length < 2) return '';
      final _IchiDaigaku tsugi = narabi[1];
      final String s = futatsuBun(tsugi, narabi[0]);
      return s == '並走'
          ? '次の${_yobi(tsugi)}と並走'
          : '次の${_yobi(tsugi)}とは$s';
    }
    final _IchiDaigaku mae = narabi[i - 1];
    final String s = futatsuBun(narabi[i], mae);
    return s == '並走' ? '前の${_yobi(mae)}と並走' : '前の${_yobi(mae)}とは$s';
  }

  String _yobi(_IchiDaigaku x) => x.op ? '学連選抜' : x.mei;
}

/// 位置関係のもとになる結果(位置関係の画面と、カードで使う)
class _IchiKankei {
  /// 1区から順
  final List<_IchiKukan> kukan;

  /// シード権の数(11月駅伝8・正月駅伝10。ほかの大会はnull)
  final int? seed;

  /// 学連選抜の監督をした年か(学連選抜をオレンジの白抜きにする)
  final bool gakurenJibun;

  /// 大会の区間数
  final int zenKukansuu;

  /// 大会番号
  final int race;

  /// 配置(区間配置確認)で選べる大学(出場校のID順。学連選抜がいる年は最後に学連選抜。2.0.9)
  final List<({int id, String mei})> haichiDaigaku;

  /// 推移の1区の演出の材料(作れなければnull。2.1.1)
  final _IkkuEnshutsu? ikku;

  _IchiKankei._(
    this.kukan,
    this.seed,
    this.gakurenJibun,
    this.zenKukansuu,
    this.race,
    this.haichiDaigaku, {
    this.ikku,
  });

  /// 大会[race]の結果から作る([made] を渡すと、レースの途中の1区から[made]区まで)
  /// (思わぬデータで画面が止まらないよう、作れなければnull)
  /// [made] が0なら、1区のスタートの前(スタートの並びだけ。2.0.7)
  static _IchiKankei? yomu(int race, {int? made}) {
    try {
      return _yomuHontai(race, made);
    } catch (e, st) {
      debugPrint('[情報集約パネル] 作れませんでした: $e\n$st');
      return null;
    }
  }

  static _IchiKankei? _yomuHontai(int race, int? made) {
    // レースの途中は、実況(kiji_jikkyou.dart)と同じく結果の記事ではない形で読む
    final KijiKankyou? k = KijiKankyou.yomuRace(race, kekka: made == null);
    if (k == null || !k.ekiden) return null;
    if (made != null && made < 0) return null;
    // 1区のスタートの前(made が0)は結果がないので、スタートの並びだけを作る(2.0.7)
    final bool startMae = made != null && made == 0;
    final EkidenKekka? e = startMae ? null : EkidenKekka.tsukuru(k, made: made);
    if (!startMae && e == null) return null;
    final UnivData? my = k.jibunUniv;
    final bool gakurenAri = race == 2 && gakurenKonnenAri(k.gh);
    // 自分の大学が出場していないか(学連選抜の監督をする年)
    final bool jibunNashi = e != null ? e.jibun == null : !(my != null && k.shutsujou(my));
    final bool gakurenJibun =
        gakurenAri && jibunNashi && my != null && gakurenKantokuChuu(k.kantoku, my);
    final List<double> kyoriIchiran = k.gh.kyori_taikai_kukangoto.length > race
        ? k.gh.kyori_taikai_kukangoto[race]
        : const <double>[];
    // 区間ごとの、区間エントリーの選手(区間 → 大学id → 選手。次の区間を走る選手に使う。2.0.7)
    final Map<int, Map<int, SenshuData>> entryHyou = {};
    for (final SenshuData s in k.senshu) {
      final int en = k.entry(s);
      if (en >= 0) (entryHyou[en] ??= <int, SenshuData>{})[s.univid] = s;
    }
    final List<_IchiKukan> kukan = [];
    // スタート(1区のスタートの前の並び。いつも一番左。2.0.7)
    final _IchiKukan? start = _startTsukuru(k, race, entryHyou, gakurenAri);
    if (start != null) kukan.add(start);
    for (int kk = 0; e != null && kk < e.ks; kk++) {
      final double kyori = kyoriIchiran.length > kk ? kyoriIchiran[kk] : 0.0;
      // 次の区間(最終区のあとはなし)
      final bool tsugiKukanAri = kk + 1 < k.kukansuu;
      final Map<int, SenshuData>? tsugiHyou = tsugiKukanAri ? entryHyou[kk + 1] : null;
      if (kyori <= 0) continue;
      // 区間終了時点の順(通過順位。記事と同じ並び)
      final List<EkidenUnivKekka> l = [
        for (final EkidenUnivKekka x in e.jun)
          if (x.ruikei[kk] > 0 &&
              x.ruikei[kk] < TEISUU.DEFAULTTIME &&
              x.kukanTime[kk] > 0 &&
              x.kukanTime[kk] < TEISUU.DEFAULTTIME)
            x,
      ]..sort((a, b) => a.tuuka[kk].compareTo(b.tuuka[kk]));
      if (l.length < 2) continue;
      // 区間の平均の速さ(出場校の区間タイムの平均から。学連選抜は入れない)
      double goukei = 0;
      for (final EkidenUnivKekka x in l) {
        goukei += x.kukanTime[kk];
      }
      final double heikin = goukei / l.length;
      if (heikin <= 0) continue;
      final List<_IchiDaigaku> narabi = [
        for (int i = 0; i < l.length; i++)
          _IchiDaigaku(
            l[i].mei,
            l[i].ruikei[kk],
            i,
            l[i].u.id == k.gh.MYunivid,
            false,
            // 前の区間の終了時点の通過順位から、いくつ上げたか(1区はなし)
            hendou: kk > 0 ? l[i].tuuka[kk - 1] - l[i].tuuka[kk] : null,
            // 走った選手と区間順位・区間タイム(四角を2回押したときの説明文に使う。2.0.7)
            senshu: l[i].senshu[kk],
            kukanJuni: _kukanJuniYomu(l[i], kk),
            kukanTime: l[i].kukanTime[kk],
            tsugiSenshu: tsugiHyou?[l[i].u.id],
            mokuhyou: l[i].u.mokuhyojuni.length > race ? l[i].u.mokuhyojuni[race] : null,
            univId: l[i].u.id,
          ),
      ];
      final GakurenKukanKekka? g = gakurenAri ? gakurenKukanKekka(k.gh, kk) : null;
      if (g != null && g.tuukaTime > 0 && g.tuukaTime < TEISUU.DEFAULTTIME) {
        // 学連選抜は、同じタイムの大学より後ろに入れる
        int basho = narabi.length;
        for (int i = 0; i < narabi.length; i++) {
          if (g.tuukaTime < narabi[i].ruikei) {
            basho = i;
            break;
          }
        }
        // 学連選抜の順位の変化は、通過順位相当で比べる(1区はなし)
        final int? gMae = g.maeTuukaJuni;
        narabi.insert(
          basho,
          _IchiDaigaku(
            '学連選抜',
            g.tuukaTime,
            -1,
            false,
            true,
            hendou: gMae == null ? null : gMae - g.tuukaJuni,
            soutouJuni: g.tuukaJuni,
            gSenshu: g.senshu,
            shozoku: g.shozoku,
            kukanJuni: g.kukanJuni,
            kukanTime: g.kukanTime,
            tsugiGSenshu: tsugiKukanAri ? gakurenKukanSenshu(kk + 1) : null,
            // 学連選抜の目標(レースの計算と同じく、監督をしていれば決めた順位、ほかは10位)
            mokuhyou: gakurenMokuhyouGenzai(),
          ),
        );
      }
      kukan.add(_IchiKukan(kk, kyori / heikin, narabi));
    }
    if (kukan.isEmpty) return null;
    // レースの途中と結果画面で、区間が1つも作れなければ(思わぬデータ)、今まで通り出さない
    if (!startMae && !kukan.any((r) => r.kk >= 0)) return null;
    final int? seed = e != null ? e.seedSuu : (race == 1 ? 8 : (race == 2 ? 10 : null));
    // 配置(区間配置確認)で選べる大学(区間配置確認の大学を選ぶ行と同じ。2.0.9)
    final List<({int id, String mei})> haichiDaigaku = [
      for (final UnivData u in k.univ)
        if (k.shutsujou(u)) (id: u.id, mei: u.name),
      if (gakurenAri) (id: kukanHaitiGakurenId, mei: '学連選抜(OP)'),
    ];
    return _IchiKankei._(
      kukan,
      seed,
      gakurenJibun,
      k.kukansuu,
      race,
      haichiDaigaku,
      ikku: e == null ? null : _IkkuEnshutsu.tsukuru(k, race, kukan),
    );
  }

  /// スタートの並び(出場校を大学のID順に並べ、学連選抜は最後。距離はみな0。
  /// 押すと1区を走る選手を出すので、tsugiSenshu に1区の選手を入れる。2.0.7)
  static _IchiKukan? _startTsukuru(
    KijiKankyou k,
    int race,
    Map<int, Map<int, SenshuData>> entryHyou,
    bool gakurenAri,
  ) {
    final Map<int, SenshuData>? ikku = entryHyou[0];
    final List<UnivData> univs = [
      for (final UnivData u in k.univ)
        if (k.shutsujou(u)) u,
    ]..sort((a, b) => a.id.compareTo(b.id));
    final List<_IchiDaigaku> narabi = [
      for (int i = 0; i < univs.length; i++)
        _IchiDaigaku(
          daigakuMei(univs[i]),
          0,
          i,
          univs[i].id == k.gh.MYunivid,
          false,
          tsugiSenshu: ikku?[univs[i].id],
          mokuhyou: univs[i].mokuhyojuni.length > race ? univs[i].mokuhyojuni[race] : null,
          univId: univs[i].id,
        ),
    ];
    if (gakurenAri) {
      final Senshu_Gakuren_Data? g = gakurenKukanSenshu(0);
      if (g != null) {
        narabi.add(
          _IchiDaigaku(
            '学連選抜',
            0,
            -1,
            false,
            true,
            tsugiGSenshu: g,
            mokuhyou: gakurenMokuhyouGenzai(),
          ),
        );
      }
    }
    if (narabi.length < 2) return null;
    return _IchiKukan(-1, 0, narabi);
  }

  /// 学連選抜が走っている区間があるか
  bool get opAri => kukan.any((r) => r.narabi.any((x) => x.op));
}

/// 区間をまたいで同じ大学を見分ける印(大学id。学連選抜は-1。推移で使う。2.1.1)
int _daigakuKagi(_IchiDaigaku x) => x.op ? -1 : (x.univId ?? -2);

/// 推移の1区の演出の材料(2.1.1。上のヘッダーの説明を参照)
class _IkkuEnshutsu {
  /// 集団の1区のタイム(秒。集団を引っ張った選手のペース)
  final double shuudanTime;

  /// 大学ごと(_daigakuKagi)の飛び出し(0: なし、1: 失敗、2: 成功)
  final Map<int, int> tobidashi;

  /// 集団を引っ張った大学(_daigakuKagi。分からなければnull)
  final int? hipparuKagi;

  const _IkkuEnshutsu(this.shuudanTime, this.tobidashi, this.hipparuKagi);

  /// 大会[race]の1区の図から作る(集団のペースの記録がない・別の大会の記録・思わぬデータのときはnull)。
  /// 飛び出しの印は選手に残っている(次の大会のエントリーで消える)ので、レースの途中と結果画面で読める
  static _IkkuEnshutsu? tsukuru(KijiKankyou k, int race, List<_IchiKukan> kukan) {
    if (k.gh.hyojiracebangou != race) return null;
    final IkkuPaceKekka? pace = ikkuPaceKekkaYomu(k.kantoku, k.gh);
    if (pace == null || pace.pace <= 0) return null;
    _IchiKukan? ikku;
    for (final _IchiKukan r in kukan) {
      if (r.kk == 0) {
        ikku = r;
        break;
      }
    }
    if (ikku == null) return null;
    final Map<int, int> tobidashi = {};
    int? hipparu;
    final List<double> shuudanTime = [];
    for (final _IchiDaigaku x in ikku.narabi) {
      final int kagi = _daigakuKagi(x);
      final int flag = x.op
          ? (x.gSenshu?.startchokugotobidasiflag ?? 0)
          : (x.senshu?.startchokugotobidasiflag ?? 0);
      final int seikou = x.op
          ? (x.gSenshu?.startchokugotobidasiseikouflag ?? 0)
          : (x.senshu?.startchokugotobidasiseikouflag ?? 0);
      final int tobi = flag == 1 ? (seikou == 1 ? 2 : 1) : 0;
      tobidashi[kagi] = tobi;
      if (tobi == 0) shuudanTime.add(x.ruikei);
      final int? pm = pace.pacemakerId;
      if (!x.op && pm != null && x.senshu?.id == pm) hipparu = kagi;
    }
    // 集団の選手の1区のタイムの真ん中が、記録の集団のペースから大きく外れていれば、別の記録とみなして使わない
    if (shuudanTime.isEmpty) return null;
    shuudanTime.sort();
    final double mannaka = shuudanTime[shuudanTime.length ~/ 2];
    if ((mannaka / pace.pace - 1).abs() > 0.1) return null;
    return _IkkuEnshutsu(pace.pace, tobidashi, hipparu);
  }
}

/// 推移の1区の演出で、1区の[x](0〜1)の地点を通る時刻(秒。2.1.1)。
/// [t] はその大学の1区のタイム、[g] は集団のタイム、[tobi] は飛び出し(0: なし、1: 失敗、2: 成功)
double _ikkuJikoku(double t, double g, int tobi, double x) {
  if (tobi == 0) {
    // 集団: 集団のペースで進み、ばらけ始めるところ(速すぎた選手は半分)からは、1区のタイムに向かってまっすぐ
    final double b = t > g * _ikkuShissokuWariai ? _ikkuShissokuIchi : _ikkuBarakeIchi;
    final double tb = g * b;
    if (t <= tb) return t * x;
    if (x <= b) return g * x;
    return tb + (t - tb) * (x - b) / (1 - b);
  }
  // 飛び出し: 区間の4割で集団との差が一番開き、そこからは1区のタイムに向かってまっすぐ
  final double sa = g * (tobi == 2 ? _ikkuTobidashiSeikou : _ikkuTobidashiShippai);
  final double tp = g * _ikkuTobidashiIchi - sa;
  if (tp <= 0 || t <= tp) return t * x;
  if (x <= _ikkuTobidashiIchi) return tp * x / _ikkuTobidashiIchi;
  return tp + (t - tp) * (x - _ikkuTobidashiIchi) / (1 - _ikkuTobidashiIchi);
}

/// 推移の1区の演出の、区間の途中の位置関係([ato] は1区の終了時点、[p] は進み具合(0〜1)。2.1.1)
/// ・同じタイムの大学(集団)は同じ順位にし、並びは集団を引っ張った大学を先頭に、大学のID順(学連選抜は最後)
///   (結果の順に並べると、集団の中の並びで結果が先に分かってしまうため)
/// ・1区なので、順位の変化(↑↓)は出さない。[p] が1なら、1区の終了時点の図と同じ中身
_IchiKukan _suiiKomaIkku(_IchiKukan ato, double p, _IkkuEnshutsu e) {
  if (p >= 1) return _IchiKukan(ato.kk, ato.hayasa, ato.narabi, suii: true);
  final double x = p < 0 ? 0.0 : p;
  final double g = e.shuudanTime;
  final List<({_IchiDaigaku d, double t, int jun})> l = [];
  for (final _IchiDaigaku d in ato.narabi) {
    final int kagi = _daigakuKagi(d);
    final double t = _ikkuJikoku(d.ruikei, g, e.tobidashi[kagi] ?? 0, x);
    final int jun = kagi == e.hipparuKagi ? -1 : (d.op ? 1000000 : (d.univId ?? 999999));
    l.add((d: d, t: t, jun: jun));
  }
  l.sort((a, b) {
    final int c = a.t.compareTo(b.t);
    return c != 0 ? c : a.jun.compareTo(b.jun);
  });
  final List<_IchiDaigaku> narabi = [];
  for (int i = 0; i < l.length; i++) {
    // 前にいる大学の数(学連選抜は数えない。同じタイムは前に数えない)
    int mae = 0;
    for (int j = 0; j < l.length; j++) {
      if (!l[j].d.op && l[j].t < l[i].t - 1e-6) mae++;
    }
    final _IchiDaigaku d = l[i].d;
    narabi.add(
      _IchiDaigaku(
        d.mei,
        l[i].t,
        d.op ? -1 : mae,
        d.jibun,
        d.op,
        soutouJuni: d.op ? mae : null,
        senshu: d.senshu,
        gSenshu: d.gSenshu,
        shozoku: d.shozoku,
        kukanJuni: d.kukanJuni,
        kukanTime: d.kukanTime,
        tsugiSenshu: d.tsugiSenshu,
        tsugiGSenshu: d.tsugiGSenshu,
        mokuhyou: d.mokuhyou,
        univId: d.univId,
      ),
    );
  }
  return _IchiKukan(ato.kk, ato.hayasa, narabi, suii: true);
}

/// 推移(2.1.1)の、区間の途中の位置関係。[mae] は前の区間の終了時点、[ato] はこの区間の終了時点、
/// [p] は区間の進み具合(0〜1)。
/// ・どの大学も、この区間を同じペースで走ったとみなし、各地点を通ったときの累計タイムを、前の中継所と
///   この中継所の累計タイムの間で直線でつなぐ(地点ごとの通過の差)
/// ・距離に換算する速さも、前の区間の速さからこの区間の速さへ少しずつ変える(区間の境目で図が跳ねないように)
/// ・順位は累計タイムの順(学連選抜は数えず、前にいる大学の数を順位相当にする)。同じタイムは、この区間の
///   終了時点の並びの順。順位の変化は、前の区間の終了時点から
/// ・[p] が1なら、この区間の終了時点の図と同じ中身を、推移の描き方(途中を省略しないなど)で描く
/// ・前の区間にいない大学(思わぬデータ)は、この区間の終了時点のタイムのまま
_IchiKukan _suiiKoma(_IchiKukan mae, _IchiKukan ato, double p) {
  // 前の中継所の累計タイム(抜いた数・抜かれた数を数えるため)と、この区間の終わりで出うる一番広い順位の変化の文
  // (抜いた数・抜かれた数は増えるだけなので、区間の終わりの数で決まる)
  final Map<int, double> maeT = {
    for (final _IchiDaigaku x in mae.narabi) _daigakuKagi(x): x.ruikei,
  };
  final List<_IchiDaigaku> owari = _nukisuuTsukeru(ato.narabi, maeT);
  final List<String> habaMoji = _suiiHendouHabaMoji(
    owari,
    ato.narabi.where((x) => !x.op).length,
  );
  if (p >= 1) {
    return _IchiKukan(ato.kk, ato.hayasa, owari, suii: true, hendouHabaMoji: habaMoji);
  }
  final double t = p < 0 ? 0.0 : p;
  final Map<int, _IchiDaigaku> maeMap = {
    for (final _IchiDaigaku x in mae.narabi) _daigakuKagi(x): x,
  };
  final List<({_IchiDaigaku x, double ruikei, int atoBan})> l = [];
  for (int i = 0; i < ato.narabi.length; i++) {
    final _IchiDaigaku x = ato.narabi[i];
    final _IchiDaigaku? m = maeMap[_daigakuKagi(x)];
    final double ruikei = m == null ? x.ruikei : m.ruikei + (x.ruikei - m.ruikei) * t;
    l.add((x: x, ruikei: ruikei, atoBan: i));
  }
  l.sort((a, b) {
    final int c = a.ruikei.compareTo(b.ruikei);
    return c != 0 ? c : a.atoBan.compareTo(b.atoBan);
  });
  final List<_IchiDaigaku> narabi = [];
  int juni = 0;
  for (final ({_IchiDaigaku x, double ruikei, int atoBan}) e in l) {
    final _IchiDaigaku x = e.x;
    // 今の順位(学連選抜は、前にいる大学の数を順位相当にする)
    final int ima = juni;
    final _IchiDaigaku? m = maeMap[_daigakuKagi(x)];
    final int? maeJuni = m == null ? null : (m.op ? m.soutouJuni : m.juni);
    narabi.add(
      _IchiDaigaku(
        x.mei,
        e.ruikei,
        x.op ? -1 : ima,
        x.jibun,
        x.op,
        hendou: maeJuni == null ? null : maeJuni - ima,
        soutouJuni: x.op ? ima : null,
        senshu: x.senshu,
        gSenshu: x.gSenshu,
        shozoku: x.shozoku,
        kukanJuni: x.kukanJuni,
        kukanTime: x.kukanTime,
        tsugiSenshu: x.tsugiSenshu,
        tsugiGSenshu: x.tsugiGSenshu,
        mokuhyou: x.mokuhyou,
        univId: x.univId,
      ),
    );
    if (!x.op) juni++;
  }
  final double hayasa = mae.hayasa > 0
      ? mae.hayasa + (ato.hayasa - mae.hayasa) * t
      : ato.hayasa;
  return _IchiKukan(
    ato.kk,
    hayasa,
    _nukisuuTsukeru(narabi, maeT),
    suii: true,
    hendouHabaMoji: habaMoji,
  );
}

/// 推移の図[ima]の大学ごとに、前の中継所からこれまでに抜いた大学の数と抜かれた大学の数を付ける(2.1.1)。
/// [maeT] は大学(_daigakuKagi)ごとの前の中継所の累計タイム。中継所で前にいて今は後ろにいる大学を「抜いた」、
/// 中継所で後ろにいて今は前にいる大学を「抜かれた」と数える(同じタイムは数えない)。学連選抜は数えない
/// (学連選抜の四角には、学連選抜が抜いた大学・抜かれた大学の数を付ける)。前の中継所にいない大学には付けない
List<_IchiDaigaku> _nukisuuTsukeru(List<_IchiDaigaku> ima, Map<int, double> maeT) {
  const double e = 1e-6;
  final List<_IchiDaigaku> kekka = [];
  for (final _IchiDaigaku a in ima) {
    final double? am = maeT[_daigakuKagi(a)];
    if (am == null) {
      kekka.add(a);
      continue;
    }
    int nuita = 0;
    int nukareta = 0;
    for (final _IchiDaigaku b in ima) {
      if (identical(a, b) || b.op) continue;
      final double? bm = maeT[_daigakuKagi(b)];
      if (bm == null) continue;
      if (bm < am - e && b.ruikei > a.ruikei + e) nuita++;
      if (bm > am + e && b.ruikei < a.ruikei - e) nukareta++;
    }
    kekka.add(a.nukisuuTsuki(nuita, nukareta));
  }
  return kekka;
}

/// 推移の四角の中の順位の変化の、色を分ける部分(fugou がプラスなら緑、マイナスなら赤。suiiHendouKata の形。
/// 変わっていなければ空。2.1.1)
List<({String moji, int fugou})> _suiiHendouBubun(_IchiDaigaku x) {
  final int h = x.hendou ?? 0;
  final int a = x.nuita ?? 0;
  final int c = x.nukareta ?? 0;
  return switch (suiiHendouKata) {
    SuiiHendouKata.nukisuu => [
      if (a > 0) (moji: '↑$a', fugou: 1),
      if (c > 0) (moji: '↓$c', fugou: -1),
    ],
    SuiiHendouKata.sashihiki => [
      if (h > 0) (moji: '↑$h', fugou: 1),
      if (h < 0) (moji: '↓${-h}', fugou: -1),
    ],
    SuiiHendouKata.yajirushi => [
      if (h > 0) (moji: '↑', fugou: 1),
      if (h < 0) (moji: '↓', fugou: -1),
    ],
  };
}

/// 推移の区間で出うる一番広い順位の変化の文([owari] は区間の終わりの図に抜いた数を付けたもの、[n] は大学の数。2.1.1)
List<String> _suiiHendouHabaMoji(List<_IchiDaigaku> owari, int n) {
  return switch (suiiHendouKata) {
    SuiiHendouKata.nukisuu => {
      for (final _IchiDaigaku x in owari)
        _suiiHendouBubun(x).map((b) => b.moji).join(),
    }.where((m) => m.isNotEmpty).toList(),
    SuiiHendouKata.sashihiki => ['↑$n', '↓$n'],
    SuiiHendouKata.yajirushi => ['↑', '↓'],
  };
}

/// 位置関係の画面を開く
void _ichiGamenHiraku(BuildContext context, int race, int? made) {
  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
    barrierDismissible: true, // 背景タップで閉じられるようにする
    barrierLabel: '情報集約パネル', // アクセシビリティ用ラベル
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) =>
        ModalIchiKankeiView(race: race, made: made),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}


/// 区間ごとのタイム分布と、情報集約パネルを1枚にまとめたカード(2.0.6)
/// ・上が「情報集約パネル」、下が「タイム分布」(Modal_kukanTimeBunpu.dart)の2つのボタンで、それぞれ別に押せる。
///   どちらも横いっぱい(2.0.6は、左にタイム分布、右に位置関係を並べていた。2.0.7で上下2段にした)。
///   中身はアイコンと見出しだけ(区間の帯のグラフなどは、開いた画面で見る)。
///   ほかのカードより目立つよう、それぞれの色(水色・青緑)の線で角を丸めて囲み、同じ色でうっすら塗る。
/// ・2.1.0から、情報集約パネルのボタンだけ大きくし(好評なので目立たせる)、左に道の小さな見取り図
///   (_mini。1位・2位と、自分の大学とその前後の5校まで。並び順どおりに置き、順位が飛ぶところに「⋮」)、
///   右に見出しと、自分の大学の今の位置のひとこと(_hitokoto)と、何の画面かの説明を出す。
///   見取り図は絵として扱い、スマホの文字の大きさの設定で大きくしない(はみ出さないように。同じ内容は
///   右のひとことに文で出す)。距離と秒は、パネルの中の帯と同じ計算
/// ・片方が作れないときは、作れたほうの1段だけ。両方とも作れなければ出さない
///   (1区の指示の画面では、タイム分布はまだ作れないので、情報集約パネルの1段だけ。2.0.7)
/// ・区間が終わるたびの画面(mode 350。[made] に終わった区間の数)の実況のカードのすぐ下と、
///   結果画面([made] はnull)のニュース記事のカードのすぐ下に置く
/// ・結果は画面を出したあとで1回だけ作る。区間や大会が変わったら作り直すよう、置く側で key を付ける
class KukanBunsekiCard extends StatefulWidget {
  /// 大会番号(0: 10月駅伝、1: 11月駅伝、2: 正月駅伝、5: カスタム駅伝)
  final int race;

  /// レースの途中のとき、終わった区間の数(結果画面ではnull)
  final int? made;
  const KukanBunsekiCard({super.key, required this.race, this.made});

  @override
  State<KukanBunsekiCard> createState() => _KukanBunsekiCardState();
}

class _KukanBunsekiCardState extends State<KukanBunsekiCard> {
  /// タイム分布が作れたか
  bool _bunpuAri = false;

  /// 位置関係が作れたか
  bool _ichiAri = false;

  /// 作った位置関係(情報集約パネルのボタンの見取り図とひとことに使う。2.1.0)
  _IchiKankei? _ichi;

  /// 結果を作ったか
  bool _tsukutta = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final KukanBunpuYomikomi? bunpu = kukanBunpuYomu(widget.race, made: widget.made);
      final _IchiKankei? ichi = _IchiKankei.yomu(widget.race, made: widget.made);
      if (!mounted) return;
      setState(() {
        _bunpuAri = bunpu != null;
        _ichiAri = ichi != null;
        _ichi = ichi;
        _tsukutta = true;
      });
    });
  }

  /// ボタン1つ(アイコンと見出し。その色の線で囲み、同じ色でうっすら塗る)
  Widget _botan(IconData icon, Color iro, String moji, VoidCallback onTap) {
    return Material(
      color: iro.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: iro, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: iro, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$moji ›',
                  style: TextStyle(color: iro, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 自分の大学(学連選抜の監督の年は学連選抜)か
  static bool _jibunKa(_IchiKankei b, _IchiDaigaku x) => x.jibun || (b.gakurenJibun && x.op);

  /// 自分の大学のひとこと(「3区終了　東西大 5位・トップから320m(58秒)」など。2.1.0)
  String _hitokoto(_IchiKankei b, _IchiKukan r) {
    if (r.kk < 0) return '1区のスタートの並びを見られます';
    final String kukan = '${r.kk + 1}区終了';
    final List<_IchiDaigaku> daigaku = [
      for (final _IchiDaigaku x in r.narabi)
        if (!x.op) x,
    ];
    String kyoriByou(int byou) => '${_kyoriMoji(byou * r.hayasa)}(${saMoji(byou)})';
    _IchiDaigaku? mitsuketa;
    for (final _IchiDaigaku x in r.narabi) {
      if (_jibunKa(b, x)) {
        mitsuketa = x;
        break;
      }
    }
    final _IchiDaigaku? j = mitsuketa;
    // 自分の大学が走っていないときは、トップと2位の差
    if (j == null) {
      if (daigaku.length < 2) return '$kukan　トップは${r.top.mei}';
      final int sa2 = saByou(daigaku[1].ruikei, daigaku[0].ruikei);
      return sa2 <= 0
          ? '$kukan　トップは${daigaku[0].mei}、2位と並走'
          : '$kukan　トップは${daigaku[0].mei}、2位と${kyoriByou(sa2)}差';
    }
    final String mei = j.op ? '学連選抜' : j.mei;
    // 1位なら、2位との差
    if (!j.op && identical(j, r.top)) {
      if (daigaku.length < 2) return '$kukan　$mei 1位';
      final int sa2 = saByou(daigaku[1].ruikei, j.ruikei);
      return sa2 <= 0 ? '$kukan　$mei 1位・2位と並走' : '$kukan　$mei 1位・2位と${kyoriByou(sa2)}差';
    }
    final String juni = j.op ? '${(j.soutouJuni ?? 0) + 1}位相当' : '${j.juni + 1}位';
    final int saTop = r.sa(j);
    if (saTop == 0) return '$kukan　$mei $juni・トップと並走';
    if (saTop < 0) return '$kukan　$mei $juni・トップより${kyoriByou(-saTop)}前';
    return '$kukan　$mei $juni・トップから${kyoriByou(saTop)}';
  }

  /// 見取り図に載せる大学(narabi の番号。1位・2位と、自分の大学とその前後。足りなければ前から5校まで)
  static List<int> _miniBangou(_IchiKankei b, _IchiKukan r) {
    final int n = r.narabi.length;
    int j = -1;
    for (int i = 0; i < n; i++) {
      if (_jibunKa(b, r.narabi[i])) {
        j = i;
        break;
      }
    }
    final Set<int> ban = {0, 1, if (j >= 0) ...[j - 1, j, j + 1]};
    ban.removeWhere((i) => i < 0 || i >= n);
    for (int i = 2; ban.length < 5 && i < n; i++) {
      ban.add(i);
    }
    return ban.toList()..sort();
  }

  /// 見取り図の四角1つ(順位と2文字の大学名。自分の大学はオレンジ、1位は白の枠)
  Widget _miniHako(_IchiKankei b, _IchiKukan r, _IchiDaigaku x) {
    final bool orange = _jibunKa(b, x);
    final bool ichii = r.kk >= 0 && identical(x, r.top);
    final Color wakuIro = orange ? _jibunIro : (ichii ? Colors.white : Colors.white38);
    final String juni = r.kk < 0 ? '' : (x.op ? 'OP ' : '${x.juni + 1} ');
    return Container(
      height: 17,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        border: Border.all(color: wakuIro, width: (orange || ichii) ? 1.5 : 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            children: [
              if (juni.isNotEmpty)
                TextSpan(text: juni, style: const TextStyle(color: Colors.white54, fontSize: 9)),
              TextSpan(
                text: x.op ? '学連' : _michiMei(x.mei),
                style: const TextStyle(color: HENSUU.textcolor, fontSize: 10),
              ),
            ],
          ),
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }

  /// 道の小さな見取り図(並び順どおりに置き、順位が飛ぶところと、後ろに続くところに「⋮」。
  /// 絵として扱い、文字の大きさの設定では大きくしない。2.1.0)
  Widget _mini(BuildContext context, _IchiKankei b, _IchiKukan r) {
    const Widget tensen = Center(
      child: Text('⋮', style: TextStyle(color: Colors.white38, fontSize: 10, height: 1.1)),
    );
    final List<int> ban = _miniBangou(b, r);
    final List<Widget> naka = [];
    for (int k = 0; k < ban.length; k++) {
      if (k > 0) naka.add(ban[k] == ban[k - 1] + 1 ? const SizedBox(height: 3) : tensen);
      naka.add(_miniHako(b, r, r.narabi[ban[k]]));
    }
    if (ban.isNotEmpty && ban.last < r.narabi.length - 1) naka.add(tensen);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Container(
        width: 72,
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
        decoration: BoxDecoration(
          color: _michiIro,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: naka,
        ),
      ),
    );
  }

  /// 情報集約パネルのボタン(ほかより大きく、左に見取り図、右に見出し・ひとこと・説明。2.1.0)
  Widget _panelBotan(BuildContext context, _IchiKankei b) {
    final _IchiKukan r = b.kukan.last;
    return Material(
      color: _iro.withOpacity(0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _iro, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _ichiGamenHiraku(context, widget.race, widget.made),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _mini(context, b, r),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.directions_run, color: _iro, size: 18),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '情報集約パネル ›',
                            style: TextStyle(color: _iro, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hitokoto(b, r),
                      style: const TextStyle(color: HENSUU.textcolor, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '道の上で、各大学の位置を見られます',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_tsukutta || (!_bunpuAri && !_ichiAri)) return const SizedBox.shrink();
    final _IchiKankei? ichi = _ichi;
    // 上に情報集約パネル、下にタイム分布(どちらも横いっぱい。2.0.7)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 情報集約パネルは大きく(見取り図とひとこと付き。2.1.0)
          if (ichi != null) _panelBotan(context, ichi),
          if (_bunpuAri && ichi != null) const SizedBox(height: 8),
          if (_bunpuAri)
            _botan(
              Icons.candlestick_chart,
              Colors.tealAccent,
              'タイム分布',
              () => kukanBunpuGamenHiraku(context, widget.race, widget.made),
            ),
        ],
      ),
    );
  }
}

class ModalIchiKankeiView extends StatefulWidget {
  /// 大会番号(0: 10月駅伝、1: 11月駅伝、2: 正月駅伝、5: カスタム駅伝)
  final int race;

  /// レースの途中のとき、終わった区間の数(結果画面からはnull)
  final int? made;
  const ModalIchiKankeiView({super.key, required this.race, this.made});

  @override
  State<ModalIchiKankeiView> createState() => _ModalIchiKankeiViewState();
}

/// 大学の四角1つ分の置き場所
class _Hako {
  /// narabi の番号
  final int i;
  final double x;
  final double w;
  final double h;
  const _Hako(this.i, this.x, this.w, this.h);
}

/// 四角を並べた行(集団は、画面の幅に入らなくなったら折り返して何行かになる)
class _Gyou {
  /// 上端
  final double y;

  /// 高さ
  final double h;

  final List<_Hako> hako;

  /// 行の右端(いちばん右の四角(か「+1秒」)の右のすきままで)
  final double hashi;

  /// 集団の中で、先頭から遅れた秒の行の右に出す文(「+1秒」)と、その左端
  /// (先頭と同じ秒の行と、折り返しの行はnull。2.1.0)
  final String? byou;
  final double byouX;

  const _Gyou(this.y, this.h, this.hako, this.hashi, {this.byou, this.byouX = 0});
}

/// 前の大学(集団)との間の括弧1つ分
class _Aida {
  /// 括弧の上端(前の集団の一番下の行の真ん中)と下端(次の集団の一番上の行の真ん中)
  final double y0;
  final double y1;

  /// 文(「90m」の下に「16秒」の2行。2.1.0)
  final String moji;

  /// 詰めた間か(括弧を点線にする。2.1.0から添え書きはなし)
  final bool tsume;

  /// 文の上端と高さ(ほかの文やシード権ラインと重ならないように決める)
  double top = 0;
  double h = 0;

  _Aida(this.y0, this.y1, this.moji, this.tsume);
}

/// 道の上の並べ方
class _Haichi {
  final List<_Gyou> gyou;

  /// 前の大学(集団)との間の括弧
  final List<_Aida> aida;

  /// 道の切れ目(詰めた間の、前の行の下端と次の行の上端)
  final List<({double y0, double y1})> kireme;

  /// 2校以上の集団を囲む枠
  final List<Rect> waku;

  /// シード権ラインの行の上端(引かないときはnull)
  final double? seedTop;

  /// 1位(いちばん前)の位置
  final double sentouY;

  /// 道の帯の上端
  final double michiUe;

  /// 道の帯の幅
  final double michiHaba;

  /// 括弧の左端と、間の文の左端
  final double kakkoX;
  final double mojiX;

  /// 全体の幅(画面より広いときは、横にスクロールする)
  final double haba;

  /// 全体の高さ
  final double takasa;

  _Haichi(
    this.gyou,
    this.aida,
    this.kireme,
    this.waku,
    this.seedTop,
    this.sentouY,
    this.michiUe,
    this.michiHaba,
    this.kakkoX,
    this.mojiX,
    this.haba,
    this.takasa,
  );
}

class _ModalIchiKankeiViewState extends State<ModalIchiKankeiView> {
  _IchiKankei? _b;

  /// 見ている区間(並びの番号)
  int _erabu = 0;

  /// 押した大学(narabi の番号。-1はなし)
  int _oshita = -1;

  /// 差の基準を目標順位にしているか(false: 1位との差、true: 目標順位との差。覚えない。2.0.7)
  bool _mokuhyouKijun = false;

  /// 押した大学の帯をどこまで開いているか(0: 差だけ、1: 走った選手の説明文、2: 次の区間を走る選手。
  /// 四角を押すたびに進む。2.0.7)
  int _hiraki = 0;

  /// 説明文と次の区間の選手の部分のスクロール(どちらか一方しか出さないので、1つを使い回す)
  final ScrollController _setsumeiScroll = ScrollController();

  /// 帯の中のスクロールする部分の中身と、その中の目印(次の区間の選手は持ちタイムの表、説明文は本文)。
  /// 同じ段のまま、ほかの大学に切り替えたときに、目印が同じ高さに来るようにするため(2.0.7)
  final GlobalKey _obiNakaKey = GlobalKey();
  final GlobalKey _ankaKey = GlobalKey();

  /// 今のゲームの変数(次の区間の選手のパネルで使う)
  Ghensuu? _gh;

  /// 持ちタイムを今季ベストで表示しているときの順位表(区間配置確認と同じ設定。初めて使うときに一度だけ作る)
  KonkiBestJuni? _konki;
  bool _konkiYonda = false;

  /// 押した大学の四角(下の帯が伸びて隠れるときに、道を動かして見えるようにする)
  final GlobalKey _oshitaKey = GlobalKey();

  /// 道の縦のスクロール(右端につまんで動かせるスクロールバーを出すため。2.1.0)
  final ScrollController _michiScroll = ScrollController();

  /// 上に固定する部分(区間の切り替えと倍率のボタン)。道が見えている高さを出すために、描いたあとに高さを測る(2.1.0)
  final GlobalKey _koteiKey = GlobalKey();

  /// 測った、上に固定する部分の高さ(測る前はnull。2.1.0)
  double? _koteiTakasa;

  /// 表示の倍率の段階(_bairitsu の番号。おまかせのときは使わない)
  int _dan = 2;

  /// 倍率がおまかせか(「−」「＋」を押すと外れる。覚えない)
  bool _omakase = true;

  /// 表示(0: 位置、1: 通過順位速報、2: 個人順位速報、3: 配置(区間配置確認。2.0.9)、4: 推移(2.1.1)。覚えない。2.0.8)
  int _hyouji = 0;

  // ---- 推移(2.1.1。上のヘッダーの説明を参照) ----
  /// 次のコマに進めるタイマー(再生しているときだけ。1コマごとに1回だけ動く)
  Timer? _suiiTimer;

  /// 推移で見ている区間(並びの番号。前の並びが1つ前の区間のときだけ。_suiiKouho)
  int _suiiKukan = 0;

  /// 再生を始めた区間(最後まで再生し終えたあとに「再生」を押すと、ここからもう一度)
  int _suiiKaishi = 0;

  /// 区間の中のコマ(0〜_suiiKomaSuu。0が区間の始め、_suiiKomaSuu が中継所)
  int _suiiKomaBan = 0;

  /// 再生しているか
  bool _saisei = false;

  /// 速さ(_suiiKomaMs の番号。1がふつう)
  int _suiiHayasaBan = 1;

  /// 焦点: 順位で追うか(true なら _shotenJuni の順位にいる大学、false なら _shotenKagi の大学)
  bool _shotenJuniMode = false;
  int _shotenJuni = 0;
  int _shotenKagi = -2;

  /// 焦点を一度決めたか(推移を初めて開いたときに、自分の大学などに決める)
  bool _shotenKimeta = false;

  /// 描いた図の中の、焦点の大学の番号(narabi の番号。いなければ-1)と、その四角の真ん中の高さ(道の上端から)
  int _suiiShotenI = -1;
  double? _suiiShotenY;

  /// 次に描いたあとに、焦点の大学まで道を動かすか(コマ・焦点・区間・倍率を変えたときと、推移を開いたとき)
  bool _suiiOuYoyaku = false;

  /// 直前に描いた推移の道の、並べ方に使った幅・文字の大きさ・倍率と、道の部分の中の道の上端の高さ
  /// (コマを変えたときに、次のコマの焦点の大学の高さを先に計算して道を先に動かすため。_suiiSakiniOu。2.1.1)
  double? _suiiMaeHaba;
  TextScaler? _suiiMaeScaler;
  double? _suiiMaePx;
  double? _suiiMaeUe;

  /// 道の部分の中身と道の帯(焦点の大学まで道を動かすときに、道の上端の高さを測る)
  final GlobalKey _suiiNakaKey = GlobalKey();
  final GlobalKey _suiiMichiKey = GlobalKey();

  /// 配置で選んだ大学(学連選抜は kukanHaitiGakurenId。nullなら最初の大学。画面を閉じるまで覚える。2.0.9)
  int? _haichiUniv;

  static const TextStyle _chiisai = TextStyle(color: Colors.white54, fontSize: 11);
  static const TextStyle _seedMojiStyle = TextStyle(color: Colors.amberAccent, fontSize: 11);
  // 道の右の差の文(2.1.0から2行にし、12から11に少し小さくした)
  static const TextStyle _migiStyle = TextStyle(color: Colors.white70, fontSize: 11);

  @override
  void initState() {
    super.initState();
    final _IchiKankei? b = _IchiKankei.yomu(widget.race, made: widget.made);
    _b = b;
    // 一番あとの区間(レースの途中は終わったばかりの区間、結果画面では最終区)を開いておく
    if (b != null) _erabu = b.kukan.length - 1;
    final Box<Ghensuu> gBox = Hive.box<Ghensuu>('ghensuuBox');
    _gh = gBox.isEmpty ? null : gBox.getAt(0);
  }

  /// 今季ベストの順位表(自己ベストで表示しているときはnull)
  KonkiBestJuni? _konkiYomu() {
    if (!_konkiYonda) {
      _konkiYonda = true;
      _konki = konkiBestHyoujiChuu() ? KonkiBestJuni() : null;
    }
    return _konki;
  }

  /// [x]の次の区間を走る選手のパネルを出せるか
  /// (区間配置確認の部品は表示中の大会を見るので、表示中の大会がこの大会のときだけ)
  bool _tsugiDaseru(_IchiDaigaku x) {
    final Ghensuu? gh = _gh;
    return x.tsugiAri && gh != null && gh.hyojiracebangou == widget.race;
  }

  @override
  void dispose() {
    _suiiTimer?.cancel();
    _setsumeiScroll.dispose();
    _michiScroll.dispose();
    super.dispose();
  }

  // ---- 推移(2.1.1) ----

  /// 推移で見られる区間か(並びの[i]番が2区より後ろで、1つ前の並びがその前の区間のとき。
  /// 1区は、1つ前がスタートで、1区の演出の材料があるとき。2.1.1)
  bool _suiiDekiru(_IchiKankei b, int i) {
    if (i < 1 || i >= b.kukan.length) return false;
    final int kk = b.kukan[i].kk;
    final int maeKk = b.kukan[i - 1].kk;
    if (kk == 0) return maeKk == -1 && b.ikku != null;
    return kk >= 1 && maeKk == kk - 1;
  }

  /// 推移の、並びの[i]番の区間の、進み具合[p]の図(1区は演出。_suiiDekiru のときだけ呼ぶ)
  _IchiKukan _suiiZu(_IchiKankei b, int i, double p) {
    final _IkkuEnshutsu? e = b.ikku;
    if (b.kukan[i].kk == 0 && e != null) return _suiiKomaIkku(b.kukan[i], p, e);
    return _suiiKoma(b.kukan[i - 1], b.kukan[i], p);
  }

  /// 推移で見られる区間(並びの番号。1区の演出ができれば1区から、できなければ2区から)
  List<int> _suiiKouho(_IchiKankei b) => [
    for (int i = 0; i < b.kukan.length; i++)
      if (_suiiDekiru(b, i)) i,
  ];

  /// 区間[kk]の距離(m。分からなければ0)
  double _suiiKyori(int kk) {
    final Ghensuu? gh = _gh;
    if (gh == null || kk < 0 || gh.kyori_taikai_kukangoto.length <= widget.race) return 0;
    final List<double> l = gh.kyori_taikai_kukangoto[widget.race];
    return l.length > kk ? l[kk] : 0.0;
  }

  /// 推移の区間の名前(「3区(21.4km)」)
  String _suiiKukanMei(_IchiKankei b, int i) {
    final int kk = b.kukan[i].kk;
    final double kyori = _suiiKyori(kk);
    return kyori > 0 ? '${kk + 1}区(${(kyori / 1000).toStringAsFixed(1)}km)' : '${kk + 1}区';
  }

  /// 推移を開いたとき(setState の中で呼ぶ)。位置で見ていた区間から始め、1区かスタートなら2区から。
  /// 焦点をまだ決めていなければ、自分の大学(学連選抜の監督の年は学連選抜。出ていなければ1位)にする
  void _suiiHiraku(_IchiKankei b) {
    final List<int> kouho = _suiiKouho(b);
    if (kouho.isEmpty) return;
    final int erabu = _erabu.clamp(0, b.kukan.length - 1);
    _suiiKukan = kouho.firstWhere((i) => i >= erabu, orElse: () => kouho.last);
    _suiiKaishi = _suiiKukan;
    _suiiKomaBan = 0;
    _saisei = false;
    _suiiTimer?.cancel();
    _suiiOuYoyaku = true;
    if (!_shotenKimeta) {
      _shotenKimeta = true;
      final List<_IchiDaigaku> narabi = b.kukan[_suiiKukan].narabi;
      if (b.gakurenJibun && narabi.any((x) => x.op)) {
        _shotenJuniMode = false;
        _shotenKagi = -1;
      } else {
        final int j = narabi.indexWhere((x) => x.jibun);
        if (j >= 0) {
          _shotenJuniMode = false;
          _shotenKagi = _daigakuKagi(narabi[j]);
        } else {
          _shotenJuniMode = true;
          _shotenJuni = 0;
        }
      }
    }
  }

  /// 推移を閉じるとき(setState の中で呼ぶ)。再生を止め、位置では推移で見ていた区間を出す
  void _suiiTojiru(_IchiKankei b) {
    _saisei = false;
    _suiiTimer?.cancel();
    if (_suiiDekiru(b, _suiiKukan)) _erabu = _suiiKukan;
  }

  /// 今のコマに止まる時間(中継所のコマは2倍)
  Duration _suiiKomaJikan() {
    final int ms = _suiiKomaMs[_suiiHayasaBan.clamp(0, _suiiKomaMs.length - 1)];
    return Duration(milliseconds: _suiiKomaBan >= _suiiKomaSuu ? ms * 2 : ms);
  }

  /// 次のコマに進めるタイマーを、今のコマに止まる時間で仕掛け直す(再生しているときだけ)
  void _suiiTimerShikakeru() {
    _suiiTimer?.cancel();
    if (!_saisei) return;
    _suiiTimer = Timer(_suiiKomaJikan(), _suiiJidouSusumu);
  }

  /// 一番最後のコマ(最後の区間の中継所)か
  bool _suiiSaigo(_IchiKankei b) {
    final List<int> kouho = _suiiKouho(b);
    return kouho.isEmpty || (_suiiKukan == kouho.last && _suiiKomaBan >= _suiiKomaSuu);
  }

  /// 一番最初のコマ(最初の区間の始め)か
  bool _suiiSaisho(_IchiKankei b) {
    final List<int> kouho = _suiiKouho(b);
    return kouho.isEmpty || (_suiiKukan == kouho.first && _suiiKomaBan <= 0);
  }

  /// 1コマ進める(setState の中で呼ぶ)。中継所の次は、次の区間の1コマ目(区間の始めは中継所と同じ図なので飛ばす)。
  /// 一番最後のコマなら何もしない
  void _suiiSusumeru(_IchiKankei b) {
    if (_suiiKomaBan < _suiiKomaSuu) {
      _suiiKomaBan++;
    } else {
      final List<int> kouho = _suiiKouho(b);
      final int ki = kouho.indexOf(_suiiKukan);
      if (ki < 0 || ki + 1 >= kouho.length) return;
      _suiiKukan = kouho[ki + 1];
      _suiiKomaBan = 1;
    }
    _suiiOuYoyaku = true;
  }

  /// 1コマ戻す(setState の中で呼ぶ)。区間の1コマ目の前は、前の区間の中継所(区間の始めと同じ図)。
  /// 一番最初のコマなら何もしない
  void _suiiModosu(_IchiKankei b) {
    final List<int> kouho = _suiiKouho(b);
    final int ki = kouho.indexOf(_suiiKukan);
    if (_suiiKomaBan <= 0) {
      // 区間の始め(前の区間の中継所と同じ図)からは、前の区間の4コマ目へ
      if (ki <= 0) return;
      _suiiKukan = kouho[ki - 1];
      _suiiKomaBan = _suiiKomaSuu - 1;
    } else if (_suiiKomaBan == 1 && ki > 0) {
      _suiiKukan = kouho[ki - 1];
      _suiiKomaBan = _suiiKomaSuu;
    } else {
      _suiiKomaBan--;
    }
    _suiiOuYoyaku = true;
  }

  /// 再生しているときに、タイマーで次のコマに進む(一番最後のコマで止める)
  void _suiiJidouSusumu() {
    final _IchiKankei? b = _b;
    if (!mounted || b == null || !_saisei || _hyouji != 4) return;
    if (!_suiiDekiru(b, _suiiKukan) || _suiiSaigo(b)) {
      _suiiTomeru();
      return;
    }
    setState(() {
      _suiiSusumeru(b);
      // 一番最後のコマ(最後の区間の中継所)まで来たら止める
      if (_suiiSaigo(b)) _saisei = false;
    });
    _suiiSakiniOu();
    _suiiTimerShikakeru();
  }

  /// 再生する(最後まで再生し終えていたら、再生を始めた区間からもう一度)
  void _suiiSaisei() {
    final _IchiKankei? b = _b;
    if (b == null) return;
    final List<int> kouho = _suiiKouho(b);
    if (kouho.isEmpty) return;
    setState(() {
      if (_suiiSaigo(b)) {
        _suiiKukan = kouho.contains(_suiiKaishi) ? _suiiKaishi : kouho.first;
        _suiiKomaBan = 0;
        _suiiOuYoyaku = true;
      } else if (_suiiKomaBan <= 0) {
        _suiiKaishi = _suiiKukan;
      }
      _saisei = true;
    });
    _suiiSakiniOu();
    _suiiTimerShikakeru();
  }

  /// 最初から(1区の演出ができればスタート、できなければ2区の始めから)最後まで通しで再生する(どの区間を見ていても)
  void _suiiSaishoKara() {
    final _IchiKankei? b = _b;
    if (b == null) return;
    final List<int> kouho = _suiiKouho(b);
    if (kouho.isEmpty) return;
    setState(() {
      _suiiKukan = kouho.first;
      _suiiKaishi = kouho.first;
      _suiiKomaBan = 0;
      _suiiOuYoyaku = true;
    });
    _suiiSakiniOu();
    _suiiSaisei();
  }

  /// 止める
  void _suiiTomeru() {
    _suiiTimer?.cancel();
    if (!mounted) return;
    setState(() => _saisei = false);
  }

  /// ◀▶(「1コマ」)。再生していれば止めてから、1コマ戻す・進める
  void _suiiKomaOkuri(bool susumu) {
    final _IchiKankei? b = _b;
    if (b == null) return;
    _suiiTimer?.cancel();
    setState(() {
      _saisei = false;
      if (susumu) {
        _suiiSusumeru(b);
      } else {
        _suiiModosu(b);
      }
    });
    _suiiSakiniOu();
  }

  /// 推移の区間を選ぶ(その区間の始めに移る。再生しているかはそのまま)
  void _suiiKukanKaeru(int i) {
    setState(() {
      _suiiKukan = i;
      _suiiKaishi = i;
      _suiiKomaBan = 0;
      _suiiOuYoyaku = true;
    });
    _suiiSakiniOu();
    _suiiTimerShikakeru();
  }

  /// 焦点の大学を、[x]の大学にする(推移で大学の四角を押したとき)
  void _suiiShotenErabu(_IchiDaigaku x) {
    setState(() {
      _shotenJuniMode = false;
      _shotenKagi = _daigakuKagi(x);
      _suiiOuYoyaku = true;
    });
    _suiiSakiniOu();
  }

  /// 図[r]の中の、焦点の大学の番号(narabi の番号。いなければ-1)
  int _suiiShotenBan(_IchiKukan r) {
    if (_shotenJuniMode) {
      // 並び(学連選抜を除く)の[j]番目の大学(1区の演出で集団が同じ順位のときも追えるように。2.1.1)
      final int n = r.narabi.where((x) => !x.op).length;
      final int j = _shotenJuni.clamp(0, math.max(0, n - 1));
      int c = 0;
      for (int i = 0; i < r.narabi.length; i++) {
        if (r.narabi[i].op) continue;
        if (c == j) return i;
        c++;
      }
      return -1;
    }
    return r.narabi.indexWhere((x) => _daigakuKagi(x) == _shotenKagi);
  }

  /// コマ・焦点・区間を変えたあと(setState のあと)に、次に描く図の焦点の大学の高さを先に計算して、
  /// 道を先に動かす(2.1.1)。描いたあとに測って動かすだけだと、新しいコマが一瞬だけ動かす前の位置で
  /// 描かれ、四角が残像のように見えていたので、コマの切り替えと道の移動を同じ描き直しで反映する。
  /// 並べ方は描くときと同じ _haichi で、直前に描いたときの幅・文字の大きさ・倍率と道の上端の高さを使う
  /// (分からなければ何もしない)。区間が変わって上の説明文の行数が変わったときや、道が長くなって
  /// 動かせる範囲が足りないときのずれは、描いたあとの _suiiOu で直す(ずれがなければ _suiiOu は何もしない)
  void _suiiSakiniOu() {
    final _IchiKankei? b = _b;
    final double? w = _suiiMaeHaba;
    final TextScaler? scaler = _suiiMaeScaler;
    final double? px = _suiiMaePx;
    final double? ue = _suiiMaeUe;
    if (!mounted || b == null || _hyouji != 4 || !_suiiOuYoyaku || !_michiScroll.hasClients) return;
    if (w == null || scaler == null || px == null || ue == null) return;
    if (!_suiiDekiru(b, _suiiKukan)) return;
    final _IchiKukan r = _suiiZu(b, _suiiKukan, _suiiKomaBan / _suiiKomaSuu);
    final int shoten = _suiiShotenBan(r);
    if (shoten < 0) return;
    final _Haichi h = _haichi(b, r, w, scaler, px, double.infinity);
    double? y;
    for (final _Gyou g in h.gyou) {
      for (final _Hako hk in g.hako) {
        if (hk.i == shoten) y = g.y + g.h / 2;
      }
    }
    if (y == null) return;
    final ScrollPosition pos = _michiScroll.position;
    // 道の部分の上の余白(SingleChildScrollView の padding の上)8を足す(_suiiOu と同じ)
    final double mokuhyou = (8 + ue + y - pos.viewportDimension * _suiiShotenTakasa)
        .clamp(pos.minScrollExtent, pos.maxScrollExtent)
        .toDouble();
    if ((mokuhyou - pos.pixels).abs() >= 0.5) _michiScroll.jumpTo(mokuhyou);
  }

  /// 焦点の大学が、道が見えている高さの上から3分の1に来るように、道を動かす(描いたあとに呼ぶ)。
  /// コマ・焦点・区間・倍率を変えたときと推移を開いたときだけ、一度に動かす(すべらせない。
  /// 指で動かした道を、コマが変わるまでは勝手に戻さないように)
  void _suiiOu() {
    if (!mounted || _hyouji != 4 || !_michiScroll.hasClients) return;
    final RenderObject? naka = _suiiNakaKey.currentContext?.findRenderObject();
    final RenderObject? michi = _suiiMichiKey.currentContext?.findRenderObject();
    if (naka is! RenderBox || michi is! RenderBox || !naka.hasSize || !michi.hasSize) return;
    double ue;
    try {
      ue = michi.localToGlobal(Offset.zero, ancestor: naka).dy;
    } catch (_) {
      return;
    }
    // 次のコマで道を先に動かすときに使う(_suiiSakiniOu。2.1.1)
    _suiiMaeUe = ue;
    if (!_suiiOuYoyaku) return;
    final double? y = _suiiShotenY;
    if (y == null) return;
    final ScrollPosition pos = _michiScroll.position;
    // 道の部分の上の余白(SingleChildScrollView の padding の上)8を足す
    final double mokuhyou = (8 + ue + y - pos.viewportDimension * _suiiShotenTakasa)
        .clamp(pos.minScrollExtent, pos.maxScrollExtent)
        .toDouble();
    _suiiOuYoyaku = false;
    if ((mokuhyou - pos.pixels).abs() < 0.5) return;
    _michiScroll.jumpTo(mokuhyou);
  }

  /// いつも出していて、つまんで動かせるスクロールバー(つまみは白っぽい色。2.1.0)
  /// (アプリの共通の見た目は明るい画面用のままなので、ふつうの Scrollbar ではつまみが黒っぽくなり、
  /// 黒い背景でほとんど見えなかった。色を決められる RawScrollbar にする)
  Widget _shiroScrollbar({
    required ScrollController controller,
    required double thickness,
    required Widget child,
  }) {
    return RawScrollbar(
      controller: controller,
      thumbVisibility: true,
      interactive: true,
      thickness: thickness,
      radius: Radius.circular(thickness / 2),
      thumbColor: Colors.white54,
      minThumbLength: 40,
      child: child,
    );
  }

  /// 上に固定する部分の高さを測る(前と違えば描き直す。文字の大きさや折り返しで変わるため。2.1.0)
  void _koteiHakaru() {
    if (!mounted) return;
    final RenderObject? ro = _koteiKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return;
    final double h = ro.size.height;
    final double? mae = _koteiTakasa;
    if (mae == null || (h - mae).abs() > 0.5) {
      setState(() => _koteiTakasa = h);
    }
  }

  /// 大学の四角を押したとき(1回目で差の帯、2回目で走った選手の説明文、3回目で次の区間を走る選手を出し、
  /// 4回目で閉じる。次の区間の選手がいなければ3回目で閉じる。
  /// 開いたまま、ほかの四角を押すと、同じ段のままその大学に切り替える。2.0.7)
  void _hakoOsu(_IchiKukan r, int i) {
    final bool tsugi = _tsugiDaseru(r.narabi[i]);
    // 切り替える前の、押していた大学・段・帯のスクロールの量・目印の高さ
    final int maeOshita = _oshita;
    final int maeHiraki = _hiraki;
    final double? maeOffset = _setsumeiScroll.hasClients ? _setsumeiScroll.offset : null;
    final double? maeAnka = _ankaIchi();
    setState(() {
      if (r.kk < 0) {
        // スタートは、1回目で1区を走る選手を出し、2回目で閉じる(2.0.7)
        if (_oshita == i) {
          _oshita = -1;
          _hiraki = 0;
        } else {
          _oshita = i;
          _hiraki = 2;
        }
      } else if (_oshita == i) {
        if (_hiraki < (tsugi ? 2 : 1)) {
          _hiraki++;
        } else {
          _oshita = -1;
          _hiraki = 0;
        }
      } else {
        _oshita = i;
        // 次の区間の選手を出していて、切り替えた大学にいなければ、説明文まで
        if (_hiraki == 2 && !tsugi) _hiraki = 1;
      }
    });
    // 同じ段のまま、ほかの大学に切り替えたか(帯のスクロールの位置を保つ。2.0.7)
    final bool tamotsu =
        maeOshita >= 0 && maeOshita != i && _oshita == i && _hiraki == maeHiraki && _hiraki > 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 帯のスクロール: 同じ段のまま切り替えたときは、目印が切り替える前と同じ高さに来るようにする
      // (測れなければスクロールの量をそのまま保つ)。段が進んだときなどは先頭に戻す
      if (_setsumeiScroll.hasClients) {
        final ScrollPosition pos = _setsumeiScroll.position;
        double ato = 0;
        if (tamotsu && maeOffset != null) {
          final double? atoAnka = _ankaIchi();
          ato = (maeAnka != null && atoAnka != null) ? maeOffset + (atoAnka - maeAnka) : maeOffset;
        }
        _setsumeiScroll.jumpTo(ato.clamp(pos.minScrollExtent, pos.maxScrollExtent).toDouble());
      }
      // 下の帯が伸びて、押した四角が隠れるときは、道を動かして見えるようにする
      final BuildContext? c = _oshitaKey.currentContext;
      if (c != null) {
        Scrollable.ensureVisible(
          c,
          duration: const Duration(milliseconds: 200),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  /// 帯の中の目印(持ちタイムの表か、説明文の本文)の、スクロールする部分の中身の上からの高さ
  /// (測れなければnull。2.0.7)
  double? _ankaIchi() {
    final RenderObject? naka = _obiNakaKey.currentContext?.findRenderObject();
    final RenderObject? anka = _ankaKey.currentContext?.findRenderObject();
    if (naka is! RenderBox || anka is! RenderBox) return null;
    if (!naka.hasSize || !anka.hasSize || !anka.attached) return null;
    try {
      return anka.localToGlobal(Offset.zero, ancestor: naka).dy;
    } catch (_) {
      return null;
    }
  }

  /// 次の区間を走る選手のパネル(区間配置確認のカードを開いたときと同じ。上の行・距離と主将・中身。
  /// 主将はカードと同じく薄い緑にして緑の枠を付ける。学連選抜は所属大学を出す。2.0.7。
  /// 2.1.0から、中身は持ちタイムの表と能力(1行に1つ。_kirokuToNouryoku))
  Widget _tsugiPanel(BuildContext context, _IchiKukan r, _IchiDaigaku x) {
    final Ghensuu? gh = _gh;
    if (gh == null) return const SizedBox.shrink();
    final int tk = r.kk + 1;
    final String fuda = '${tk + 1}区';
    final List<double> kyoriIchiran = gh.kyori_taikai_kukangoto.length > widget.race
        ? gh.kyori_taikai_kukangoto[widget.race]
        : const <double>[];
    final String kyori = kyoriIchiran.length > tk ? '${kyoriIchiran[tk].toStringAsFixed(0)}m' : '';
    const TextStyle shita = TextStyle(color: Colors.white70, fontSize: 13);
    final SenshuData? s = x.tsugiSenshu;
    final Senshu_Gakuren_Data? g = x.tsugiGSenshu;
    if (s != null) {
      final bool shushou = shushouKaIma(s);
      final Widget panel = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          senshuHaichiTitle(
            context,
            fuda: fuda,
            fudaIro: Colors.cyanAccent,
            mei: s.name,
            gakunen: s.gakunen,
            shousaiId: s.id,
          ),
          Text([if (kyori.isNotEmpty) kyori, if (shushou) '主将'].join('　'), style: shita),
          const Divider(color: Colors.white24),
          // 中身(2.1.0から、持ちタイムの表と能力(1行に1つ)。2回目の走った選手と同じ並び。
          // 持ちタイムの表に、ほかの大学に切り替えたときに同じ高さに来るようにする目印を付ける)
          _kirokuToNouryoku(s: s, kukanIdx: tk, kirokuAnka: true) ?? const SizedBox.shrink(),
        ],
      );
      if (!shushou) return panel;
      return Container(
        padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
        decoration: BoxDecoration(
          color: shushouIroHaikei,
          border: Border.all(color: shushouIroSen, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: panel,
      );
    }
    if (g != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          senshuHaichiTitle(
            context,
            fuda: fuda,
            fudaIro: Colors.cyanAccent,
            mei: g.name,
            gakunen: g.gakunen,
            shousaiId: g.id,
          ),
          Text('$kyori 所属:${gakurenShozoku(g)}', style: shita),
          const Divider(color: Colors.white24),
          _kirokuToNouryoku(g: g, kukanIdx: tk, kirokuAnka: true) ?? const SizedBox.shrink(),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  /// 持ちタイムの表と能力(1行に1つ)。2回目に押したときは走った選手、3回目は次の区間を走る選手(2.1.0。
  /// 答え合わせと次の予想を同じ並びで見られるように)。[kukanIdx] はその選手の区間(この区間の経験回数に使う)。
  /// 区間配置確認のカードを開いた中身のうち、能力の行(駅伝男・平常心・調子・この区間の経験回数)は、
  /// 下の能力に全部入るので出さない。まだ見抜いていない能力は「??」。学連選抜の選手の調子は学連選抜で走ったときの調子。
  /// [kirokuAnka] がtrueなら、持ちタイムの表に、同じ段のままほかの大学に切り替えたときにそろえる目印を付ける(3回目)。
  /// 選手が分からなければnull
  Widget? _kirokuToNouryoku({
    SenshuData? s,
    Senshu_Gakuren_Data? g,
    required int kukanIdx,
    required bool kirokuAnka,
  }) {
    final Ghensuu? gh = _gh;
    if (gh == null || kukanIdx < 0) return null;
    final KonkiBestJuni? konki = _konkiYomu();
    final Widget kiroku;
    final Widget nouryoku;
    if (s != null) {
      kiroku = senshuKirokuRan(gh, s, konki);
      nouryoku = senshuNouryokuZenbu(gh, s, race: widget.race, kukanIdx: kukanIdx);
    } else if (g != null) {
      kiroku = gakurenKirokuRan(gh, g, konki);
      nouryoku = gakurenNouryokuZenbu(gh, g, race: widget.race, kukanIdx: kukanIdx);
    } else {
      return null;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('持ちタイム', style: _chiisai),
        const SizedBox(height: 2),
        // 持ちタイムの表は、区間配置確認のカードと同じく真ん中に寄せる
        Center(child: kirokuAnka ? KeyedSubtree(key: _ankaKey, child: kiroku) : kiroku),
        const Divider(height: 12, color: Colors.white24),
        const Text('能力', style: _chiisai),
        const SizedBox(height: 2),
        nouryoku,
      ],
    );
  }

  /// 説明文の上の行(「3区 佐藤 健太(2年)　区間1位 1:02:41」。
  /// 学連選抜は「3区 OP 田中 翔(3年 所属:西峰大)　区間4位相当 1:03:05」。2.0.7)
  String _senshuGyou(_IchiKukan r, _IchiDaigaku x) {
    final String ku = '${r.kk + 1}区';
    String mei = '';
    final SenshuData? s = x.senshu;
    final Senshu_Gakuren_Data? g = x.gSenshu;
    if (s != null) {
      mei = ' ${s.name}(${s.gakunen}年${shushouShirushi(s)})';
    } else if (g != null) {
      mei = ' OP ${g.name}(${g.gakunen}年 所属:${x.shozoku ?? ''})';
    }
    final int? kj = x.kukanJuni;
    final double? kt = x.kukanTime;
    final String juni = kj == null ? '' : (x.op ? '区間${kj + 1}位相当' : '区間${kj + 1}位');
    final String time = (kt != null && kt > 0 && kt < TEISUU.DEFAULTTIME)
        ? TimeDate.timeToFunByouString(kt)
        : '';
    final String ato = [juni, time].where((e) => e.isNotEmpty).join(' ');
    return ato.isEmpty ? '$ku$mei' : '$ku$mei　$ato';
  }

  /// 区間の名前(「スタート」「3区」。2.0.7)
  String _kukanMei(_IchiKukan r) => r.kk < 0 ? 'スタート' : '${r.kk + 1}区';

  /// 四角の中の順位の欄の文(学連選抜は「OP」。スタートは大学は空。2.1.0)
  String _juniMoji(_IchiKukan r, int i) {
    final _IchiDaigaku x = r.narabi[i];
    if (x.op) return 'OP';
    return r.kk < 0 ? '' : '${x.juni + 1}';
  }

  /// 四角の中の大学名(最後の「大」を省く。学連選抜は「学連」。下の帯は省かない)
  String _hakoMei(_IchiDaigaku x) => x.op ? '学連' : _michiMei(x.mei);

  /// 四角の中の欄の幅を、区間と文字の大きさごとに覚えておく(画面を開いているあいだだけ。2.1.0)
  final Map<String, _HakoHaba> _hakoHabaKioku = {};

  /// 区間[r]の四角の中の欄の幅(2.1.0)
  /// 順位の欄はその区間の一番広い順位(学連選抜の「OP」も)、大学名の欄の上限は4文字分(_meiMojisuu)、
  /// 順位の変化の欄はその区間の一番広い変化(1区とスタートは変化がないので0)
  _HakoHaba _hakoHaba(_IchiKukan r, TextScaler scaler) {
    // 推移(2.1.1)は、位置の図と別に覚える
    final String kagi = '${r.kk}${r.suii ? 's' : ''}:${scaler.scale(100).toStringAsFixed(2)}';
    final _HakoHaba? kioku = _hakoHabaKioku[kagi];
    if (kioku != null) return kioku;
    double juni = 0;
    double hendou = 0;
    double takasa = 0;
    for (int i = 0; i < r.narabi.length; i++) {
      final String jm = _juniMoji(r, i);
      if (jm.isNotEmpty) {
        final Size z = _ookisa(TextSpan(text: jm, style: _juniStyle), scaler);
        juni = math.max(juni, z.width);
        takasa = math.max(takasa, z.height);
      }
      final String? hm = _hendouHyouji(r, r.narabi[i]);
      if (hm != null) {
        final Size z = _ookisa(TextSpan(text: hm, style: _hendouStyle), scaler);
        hendou = math.max(hendou, z.width);
        takasa = math.max(takasa, z.height);
      }
    }
    // 推移(2.1.1)は、地点ごとに順位と順位の変化が変わるので、出うる一番広い文でも測る
    // (区間の途中で欄の幅が変わって、四角の大きさが揺れないように。順位の変化は suiiHendouKata の形で、
    // その区間の終わりまでに出うる一番広い文(_suiiHendouHabaMoji))
    if (r.suii) {
      final int n = r.narabi.where((x) => !x.op).length;
      final Size jz = _ookisa(TextSpan(text: '$n', style: _juniStyle), scaler);
      juni = math.max(juni, jz.width);
      takasa = math.max(takasa, jz.height);
      if (r.kk > 0) {
        for (final String hm in r.hendouHabaMoji) {
          final Size z = _ookisa(TextSpan(text: hm, style: _hendouStyle), scaler);
          hendou = math.max(hendou, z.width);
          takasa = math.max(takasa, z.height);
        }
      }
    }
    // 大学名の欄の上限は「国」4文字分
    final Size mei = _ookisa(TextSpan(text: '国' * _meiMojisuu, style: _meiStyle), scaler);
    takasa = math.max(takasa, mei.height);
    final _HakoHaba h = _HakoHaba(juni, mei.width, hendou, takasa);
    _hakoHabaKioku[kagi] = h;
    return h;
  }

  /// 四角の中(順位・大学名・順位の変化の欄を並べる。順位と変化の欄は区間でそろえ、大学名は名前の長さ。2.1.0)
  Widget _hakoNaka(_IchiKukan r, int i, TextScaler scaler) {
    final _HakoHaba h = _hakoHaba(r, scaler);
    final _IchiDaigaku x = r.narabi[i];
    final List<({String moji, int fugou})> bubun = _hendouBubun(r, x);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 順位(学連選抜は「OP」。順位と同じ薄い色。右寄せ)
        if (h.juni > 0) ...[
          SizedBox(
            width: h.juni,
            child: Text(
              _juniMoji(r, i),
              style: _juniStyle,
              textAlign: TextAlign.right,
              maxLines: 1,
              softWrap: false,
            ),
          ),
          const SizedBox(width: _juniSukima),
        ],
        // 大学名(自分の大学も、文字はほかの大学と同じ。オレンジは枠だけ)
        _hakoMeiWidget(_hakoMei(x), h, scaler),
        // 前の区間からの順位の変化(↑は緑、↓は赤、→は灰色。1区とスタートは欄を作らない)
        if (h.hendou > 0) ...[
          const SizedBox(width: _hendouSukima),
          SizedBox(
            width: h.hendou,
            // (推移の「↑3↓1」のように、上げた・下げたを色分けして並べる。2.1.1)
            child: bubun.isEmpty
                ? null
                : Text.rich(
                    TextSpan(
                      children: [
                        for (final ({String moji, int fugou}) bb in bubun)
                          TextSpan(
                            text: bb.moji,
                            style: _hendouStyle.copyWith(color: _hendouIro(bb.fugou)),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
          ),
        ],
      ],
    );
  }

  /// 四角の中の大学名の欄の幅(名前の長さ。上限は4文字分。2.1.0)
  double _hakoMeiHaba(String mei, _HakoHaba h, TextScaler scaler) =>
      math.min(_ookisa(TextSpan(text: mei, style: _meiStyle), scaler).width, h.mei);

  /// 四角の中の大学名(名前の長さの欄。4文字分(_meiMojisuu)より長い名前は、4文字分に横だけ縮め、
  /// 5割まで縮めても入らなければ最後を「…」で省く。2.1.0)
  Widget _hakoMeiWidget(String mei, _HakoHaba h, TextScaler scaler) {
    final Size shizen = _ookisa(TextSpan(text: mei, style: _meiStyle), scaler);
    if (shizen.width <= h.mei) {
      return SizedBox(
        width: shizen.width,
        child: Text(mei, style: _meiStyle, maxLines: 1, softWrap: false),
      );
    }
    String moji = mei;
    Size z = shizen;
    while (moji.length > 1 && z.width * _meiChijimiSaishou > h.mei) {
      moji = moji.substring(0, moji.length - 1);
      z = _ookisa(TextSpan(text: '$moji…', style: _meiStyle), scaler);
    }
    final String hyouji = moji == mei ? mei : '$moji…';
    // 高さは文の高さのまま、横だけを欄の幅に合わせて縮める
    return SizedBox(
      width: h.mei,
      height: z.height,
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.centerLeft,
        child: Text(hyouji, style: _meiStyle, maxLines: 1, softWrap: false),
      ),
    );
  }

  /// 四角の中の順位の変化の、色を分ける部分(位置は「↑2」「↓3」「→」の1つ。推移は suiiHendouKata の形で、
  /// 変わらなければなし。1区の演出のあいだはなし。2.1.1)
  List<({String moji, int fugou})> _hendouBubun(_IchiKukan r, _IchiDaigaku x) {
    if (r.suii) return r.kk <= 0 ? const [] : _suiiHendouBubun(x);
    final String? m = x.hendouMoji;
    final int? h = x.hendou;
    if (m == null || h == null) return const [];
    return [(moji: m, fugou: h)];
  }

  /// 四角の中の順位の変化の文(欄の幅を測るのに使う。なければnull)
  String? _hendouHyouji(_IchiKukan r, _IchiDaigaku x) {
    final List<({String moji, int fugou})> bubun = _hendouBubun(r, x);
    return bubun.isEmpty ? null : bubun.map((b) => b.moji).join();
  }

  /// 順位の変化の色
  Color _hendouIro(int h) =>
      h > 0 ? Colors.lightGreenAccent : (h < 0 ? Colors.redAccent.shade100 : Colors.white54);

  /// 四角の大きさ(枠の太さの最大と余白を見込む。2.1.0から、高さは区間の中で同じ、幅は大学名の長さで変わる)
  Size _hakoOokisa(_IchiKankei b, _IchiKukan r, int i, TextScaler scaler) {
    final _HakoHaba h = _hakoHaba(r, scaler);
    final double meiHaba = _hakoMeiHaba(_hakoMei(r.narabi[i]), h, scaler);
    return Size(
      h.naka(meiHaba) + _hakoYoko * 2 + _wakuSaidai * 2 + 2,
      h.takasa + _hakoTate * 2 + _wakuSaidai * 2,
    );
  }

  /// 一番長い差の文の幅を、文字の大きさごとに覚えておく(画面を開いているあいだだけ。2.1.0)
  final Map<String, double> _aidaMojiHabaKioku = {};

  /// パネルで見られる全部の区間(スタートと終わった区間)の、一番長い差の文の幅(2.1.0)
  /// 道の帯の幅と1行に並べる幅をこれで決める(区間を切り替えるたびに道の幅が変わらないように)
  double _aidaMojiHabaSaidai(_IchiKankei b, TextScaler scaler) {
    final String kagi = scaler.scale(100).toStringAsFixed(2);
    final double? kioku = _aidaMojiHabaKioku[kagi];
    if (kioku != null) return kioku;
    double moji = 0;
    for (final _IchiKukan r in b.kukan) {
      for (int i = 1; i < r.narabi.length; i++) {
        moji = math.max(
          moji,
          _ookisa(TextSpan(text: r.aidaBun(r.narabi[i], r.narabi[i - 1]), style: _migiStyle), scaler).width,
        );
      }
    }
    _aidaMojiHabaKioku[kagi] = moji;
    return moji;
  }

  /// 集団の1行に四角(と「+1秒」)を並べてよい右端(2.1.0)
  /// 「四角の行 + 右の括弧と差の文」が画面の幅[w]に入るところまで。区間を切り替えても同じ並びなら同じ折り返しに
  /// なるように、右の差の文は、パネルで見られる全部の区間で一番長い文で見込む(_haichi の道の幅の決め方と同じ)
  double _gyouJougen(_IchiKankei b, double w, TextScaler scaler) =>
      w - _wakuYohaku - _migiYohaku - _aidaMojiHabaSaidai(b, scaler);

  /// 文の大きさ(折り返さない。改行のある文は、行を重ねた大きさ。2.1.0から道の右の差の文が2行になったため、
  /// 行の数を1つに限らないようにした)
  Size _ookisa(TextSpan span, TextScaler scaler) {
    final TextPainter tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final Size s = tp.size;
    tp.dispose();
    return s;
  }

  /// 前の大学との間(m。[i]は narabi[i] と narabi[i+1] の間)
  List<double> _aida(_IchiKukan r) => [
    for (int i = 0; i + 1 < r.narabi.length; i++)
      math.max(0.0, (r.narabi[i + 1].ruikei - r.narabi[i].ruikei) * r.hayasa),
  ];

  /// 詰める間(_aida の番号。1mあたり[px]で描くと、道が見えている高さ[gamenTakasa]より長くなる間。2.1.0)
  Set<int> _tsumeAida(List<double> aida, double px, double gamenTakasa) => {
    for (int i = 0; i < aida.length; i++)
      if (aida[i] * px > gamenTakasa) i,
  };

  /// おまかせの倍率の段階(詰めた間を除いた1位から最後尾までの長さが、
  /// 道が見えている高さ[gamenTakasa]のおよそ2つ分に収まる一番大きい倍率)
  int _omakaseDan(_IchiKukan r, double gamenTakasa) {
    if (r.narabi.length < 2 || r.kk < 0) return 2;
    final List<double> aida = _aida(r);
    int dan = 0;
    for (int i = 0; i < _bairitsu.length; i++) {
      // 詰める間は倍率ごとに違うので、倍率ごとに数え直す(2.1.0)
      final Set<int> tsume = _tsumeAida(aida, _bairitsu[i], gamenTakasa);
      double nokori = 0;
      for (int j = 0; j < aida.length; j++) {
        if (!tsume.contains(j)) nokori += aida[j];
      }
      if (nokori * _bairitsu[i] + tsume.length * _tsumePx <= gamenTakasa * _omakaseGamen) {
        dan = i;
      }
    }
    // ×4より小さくはしない(2.1.0。縦が長くなっても、数十mの差が見分けられるように)
    return math.max(dan, _omakaseSaitei);
  }

  /// 大学の四角と行の置き場所を決める([px] は1mあたりの高さ。[gamenTakasa] は道が見えている高さ。
  /// 1つの間が道が見えている高さを超えるところだけを詰める(2.0.9までは手動で倍率を選んでいるときだけ。2.1.0から、
  /// おまかせが×4より小さくならず、1つの間が画面より長くなることがあるので、おまかせでも詰める)。
  /// 集団の1行には、画面の幅に入るだけ並べる(_gyouJougen。2.1.0)
  _Haichi _haichi(
    _IchiKankei b,
    _IchiKukan r,
    double w,
    TextScaler scaler,
    double px,
    double gamenTakasa,
  ) {
    // 集団の1行に四角(と「+1秒」)を並べてよい右端(2.1.0)
    final double jougen = _gyouJougen(b, w, scaler);
    final int n = r.narabi.length;
    // 四角の大きさ(折り返さない1行)
    final List<Size> hakoOokisa = [
      for (int i = 0; i < n; i++) _hakoOokisa(b, r, i, scaler),
    ];
    // 行の高さ(四角の高さ。どの行も同じ)
    double gyouTakasa = 0;
    for (final Size s in hakoOokisa) {
      gyouTakasa = math.max(gyouTakasa, s.height);
    }
    // 間の文の高さ(距離と秒差の2行。2.1.0)
    final double aidaMojiTakasa = _ookisa(const TextSpan(text: '0m\n0秒', style: _migiStyle), scaler).height;
    // 詰めた間の、前の行の真ん中から次の行の真ん中までの長さ(2行の文が入るように)
    final double tsumeNagasa = math.max(
      _tsumePx,
      gyouTakasa + aidaMojiTakasa + _sukima * 2,
    );
    final double seedTakasa = _ookisa(
      const TextSpan(text: 'シード権ライン', style: _seedMojiStyle),
      scaler,
    ).height;
    final int opNozoku = r.narabi.where((x) => !x.op).length;
    // シード権ライン(スタートは引かない。2.0.7)
    final int? seed = (r.kk >= 0 && b.seed != null && opNozoku > b.seed!) ? b.seed : null;
    // ラインを引く場所: シード権の最後の順位(正月駅伝は10位)の大学のすぐ下(narabi のこの番号の前)。
    // 学連選抜が10位と11位の間にいても、学連選抜はラインの下になる(シード権はないので。2.1.0。
    // それまでは11位の大学のすぐ上に引いていたので、学連選抜がラインの上に出ていた)
    int? seedMaeBangou;
    // シード権の最後の順位の大学が何校もある(推移の1区の演出で、集団が同じ順位のとき。2.1.1)ときは引かない
    final int seedSaigo = seed == null ? -1 : seed - 1;
    if (seed != null &&
        r.narabi.where((x) => !x.op && x.juni == seedSaigo).length == 1) {
      for (int i = 0; i + 1 < n; i++) {
        if (!r.narabi[i].op && r.narabi[i].juni == seed - 1) {
          seedMaeBangou = i + 1;
          break;
        }
      }
    }

    // 詰める間(画面の高さを超える間だけ。2.1.0から、おまかせでも詰める。飛び抜けて大きい間を詰めるのはやめた)
    final List<double> aida = _aida(r);
    final Set<int> tsume = _tsumeAida(aida, px, gamenTakasa);

    // 1位(いちばん前)からの距離(m)
    final double base = r.narabi.first.ruikei;
    final List<double> d = [for (final _IchiDaigaku x in r.narabi) (x.ruikei - base) * r.hayasa];

    // 集団に分ける(2.1.0): 前の大学との差が1秒以内(右の括弧と同じ切り捨ての秒。「並走」か「1秒」)なら、
    // 同じ集団としてつなげる(長さの上限はなし。拡大・縮小しても変わらない)。
    // シード権ラインと、詰めた間では必ず分ける。
    // (2.0.9までは、画面の上で四角1つ分より近い大学をつなげ、長い集団は一番大きく空いた間で分けていた。
    // 倍率が小さいと100m以上離れた大学も同じ枠に入り、集団走のように見えていた)
    final List<List<int>> shuudan = [];
    for (int i = 0; i < n; i++) {
      final _IchiDaigaku x = r.narabi[i];
      final bool seedMae = i == seedMaeBangou;
      final bool kiremeAto = i > 0 && tsume.contains(i - 1);
      final bool chikai =
          i > 0 && saByou(x.ruikei, r.narabi[i - 1].ruikei) <= _shuudanByou;
      if (shuudan.isNotEmpty && chikai && !seedMae && !kiremeAto) {
        shuudan.last.add(i);
      } else {
        shuudan.add([i]);
      }
    }

    // 集団ごとに置く(一番上の行は前の集団の一番下の行から、間の距離ぶん下。1行には画面の幅に入るだけ)
    final List<_Gyou> gyou = [];
    final List<_Aida> aidaList = [];
    final List<({double y0, double y1})> kireme = [];
    final List<Rect> waku = [];
    // 2校以上の集団の、行の範囲(gyou の番号。kara から made の前まで)と枠の上端・下端
    // (枠の左右は、道の幅が決まって四角を真ん中に寄せたあとで決める。2.1.0)
    final List<({int kara, int made, double ue, double shita})> wakuKumi = [];
    double? seedTop;
    // 道の帯は、いちばん上から始める(2.0.6の開発中まで、上に「○区→○区の中継所」を出していた)
    const double michiUe = 0;
    double shita = michiUe; // いま置いたものの下端
    double sentouY = michiUe + _sukima + gyouTakasa / 2;
    double? maeChuushin; // 前の集団の一番下の行の真ん中
    double maeGyouShita = michiUe; // 前の集団の一番下の行の下端
    int maeSaigo = 0; // 前の集団の最後の大学
    for (int si = 0; si < shuudan.length; si++) {
      final List<int> sh = shuudan[si];
      final int saki = sh.first;
      double top;
      final double? mc = maeChuushin;
      final bool tsumeAto = mc != null && tsume.contains(saki - 1);
      if (mc == null) {
        top = michiUe + _sukima;
      } else if (tsumeAto) {
        // 詰めた間: 決まった長さだけ空ける(道には切れ目の点線、右には点線の括弧)
        top = mc + tsumeNagasa - gyouTakasa / 2;
      } else {
        top = mc + (d[saki] - d[maeSaigo]) * px - gyouTakasa / 2;
      }
      // シード権ライン(シード権の最後の順位の大学のすぐ下。学連選抜がいても、その上。2.1.0)
      if (saki == seedMaeBangou) {
        final double sTop = shita + _sukima;
        seedTop = sTop;
        shita = sTop + seedTakasa;
      }
      // 2校以上の集団は枠で囲むので、枠の余白のぶんも空ける
      final bool wakuAri = sh.length >= 2;
      top = math.max(
        top,
        si == 0 ? shita + _sukima + (wakuAri ? _wakuYohaku : 0) : shita + _shuudanSukima + (wakuAri ? _wakuYohaku : 0),
      );
      // 前の集団との間は、2行の差の文が括弧の中に収まる高さより狭くしない(2.1.0。文字を大きくしていても、
      // 文が少しずつ下にずれて括弧と合わなくならないように)
      if (mc != null) {
        final double mojiTakasa = _ookisa(
          TextSpan(text: r.aidaBun(r.narabi[saki], r.narabi[maeSaigo]), style: _migiStyle),
          scaler,
        ).height;
        top = math.max(top, mc + mojiTakasa + 2 - gyouTakasa / 2);
      }
      if (si == 0) sentouY = top + gyouTakasa / 2;
      // 前の集団との間の括弧(前の集団の一番下の行の真ん中から、この集団の一番上の行の真ん中まで)
      if (mc != null) {
        aidaList.add(
          _Aida(mc, top + gyouTakasa / 2, r.aidaBun(r.narabi[saki], r.narabi[maeSaigo]), tsumeAto),
        );
        if (tsumeAto) kireme.add((y0: maeGyouShita, y1: top));
      }
      final double shuudanUe = top;
      final int gyouKara = gyou.length;
      // 集団の中は、先頭からの秒差ごとに行を分ける(2.1.0。同じ秒の大学を横に並べ、画面の幅に入らなくなったら
      // 折り返す(数の上限はなし。1行に1校は置く)。秒が変わった行の右に「+1秒」を出し、折り返しの行には出さない)
      final List<({List<int> ichi, int? byou})> kumi = [];
      int j = 0;
      while (j < sh.length) {
        final int byou0 = saByou(r.narabi[sh[j]].ruikei, r.narabi[saki].ruikei);
        final List<int> onaji = [];
        while (j < sh.length &&
            saByou(r.narabi[sh[j]].ruikei, r.narabi[saki].ruikei) == byou0) {
          onaji.add(sh[j]);
          j++;
        }
        int k = 0;
        while (k < onaji.length) {
          // 秒が変わった最初の行は、右の「+1秒」の幅も見込む
          final bool byouAri = k == 0 && byou0 > 0;
          final double byouMojiHaba = byouAri
              ? _ookisa(TextSpan(text: '+$byou0秒', style: _chiisai), scaler).width + _sukima
              : 0;
          final List<int> gyouNoIchi = [];
          double gyouHashi = _hakoHidari;
          while (k < onaji.length) {
            final double tsugiHaba = hakoOokisa[onaji[k]].width + _sukima;
            if (gyouNoIchi.isNotEmpty && gyouHashi + tsugiHaba + byouMojiHaba > jougen) break;
            gyouNoIchi.add(onaji[k]);
            gyouHashi += tsugiHaba;
            k++;
          }
          kumi.add((ichi: gyouNoIchi, byou: byouAri ? byou0 : null));
        }
      }
      for (final ({List<int> ichi, int? byou}) g in kumi) {
        final List<_Hako> hako = [];
        double x = _hakoHidari;
        for (final int idx in g.ichi) {
          final Size z = hakoOokisa[idx];
          hako.add(_Hako(idx, x, z.width, z.height));
          x += z.width + _sukima;
        }
        String? byouMoji;
        double byouX = 0;
        if (g.byou != null) {
          byouMoji = '+${g.byou}秒';
          byouX = x;
          x += _ookisa(TextSpan(text: byouMoji, style: _chiisai), scaler).width + _sukima;
        }
        gyou.add(_Gyou(top, gyouTakasa, hako, x, byou: byouMoji, byouX: byouX));
        shita = top + gyouTakasa;
        top = shita + _sukima;
      }
      maeChuushin = shita - gyouTakasa / 2;
      maeGyouShita = shita;
      maeSaigo = sh.last;
      // 2校以上の集団を囲む枠(上下はここで決め、左右は四角を真ん中に寄せたあとで決める)
      if (wakuAri) {
        wakuKumi.add((
          kara: gyouKara,
          made: gyou.length,
          ue: shuudanUe - _wakuYohaku,
          shita: shita + _wakuYohaku,
        ));
        shita += _wakuYohaku;
      }
    }

    // 間の文の置き場所(括弧の真ん中。前の文と重なるときは、下にずらす)
    // (2.0.9まではシード権ラインが画面の幅いっぱいだったので、ラインと重なる文もその下にずらしていた。
    // 2.1.0からラインは道の帯の上だけに引くので、右の文はずらさない)
    double maeMojiShita = -1;
    for (final _Aida a in aidaList) {
      a.h = _ookisa(TextSpan(text: a.moji, style: _migiStyle), scaler).height;
      final double t = math.max((a.y0 + a.y1) / 2 - a.h / 2, maeMojiShita + 2);
      a.top = t;
      maeMojiShita = t + a.h;
    }

    // 幅(道の帯は、画面の幅から括弧と差の文の幅を引いた残り全部か、一番広い行の広いほう。2.1.0。
    // 差の文の幅は、区間を切り替えても道の幅が変わらないように、パネルの全部の区間で一番長い文で決める。
    // 四角の行が広くて入りきらなければ横にスクロール)
    double gyouHaba = 0;
    for (final _Gyou g in gyou) {
      gyouHaba = math.max(gyouHaba, g.hashi);
    }
    double mojiHaba = 0;
    for (final _Aida a in aidaList) {
      mojiHaba = math.max(mojiHaba, _ookisa(TextSpan(text: a.moji, style: _migiStyle), scaler).width);
    }
    final double zentaiMoji = math.max(mojiHaba, _aidaMojiHabaSaidai(b, scaler));
    final double michiHaba = math.max(w - _migiYohaku - zentaiMoji, gyouHaba + _wakuYohaku);
    final double kakkoX = michiHaba + 6;
    final double mojiX = kakkoX + 14;
    final double haba = math.max(w, mojiX + mojiHaba + 8);

    // 四角を行ごとに道の左右の真ん中に置く(2.1.0。集団が隊列のような形に見えるように)。
    // 真ん中にそろえるのは四角だけで、「+1秒」はその右に出す。「+1秒」が道からはみ出すときと、
    // 行が道より広いときは、入るところまで左に寄せる(左端は今までの並べ始めの位置まで)
    final double naka = michiHaba / 2;
    for (int gi = 0; gi < gyou.length; gi++) {
      final _Gyou g = gyou[gi];
      if (g.hako.isEmpty) continue;
      final double hakoHidari = g.hako.first.x;
      final double hakoMigi = g.hako.last.x + g.hako.last.w;
      final double hakoHaba = hakoMigi - hakoHidari;
      // 「+1秒」の分(四角の右のすきまと文の幅。なければ0)
      final double byouHaba = g.byou != null ? (g.hashi - _sukima) - hakoMigi : 0;
      double hidari = naka - hakoHaba / 2;
      hidari = math.min(hidari, michiHaba - _wakuYohaku - hakoHaba - byouHaba);
      hidari = math.max(hidari, _hakoHidari);
      final double dx = hidari - hakoHidari;
      if (dx == 0) continue;
      gyou[gi] = _Gyou(
        g.y,
        g.h,
        [for (final _Hako hk in g.hako) _Hako(hk.i, hk.x + dx, hk.w, hk.h)],
        g.hashi + dx,
        byou: g.byou,
        byouX: g.byouX + dx,
      );
    }
    // 2校以上の集団を囲む枠(道の真ん中を軸に左右同じ幅で、四角と「+1秒」を囲む。道からははみ出さない)
    for (final ({int kara, int made, double ue, double shita}) k in wakuKumi) {
      double hidari = double.infinity;
      double migi = 0;
      for (int gi = k.kara; gi < k.made; gi++) {
        final _Gyou g = gyou[gi];
        if (g.hako.isEmpty) continue;
        hidari = math.min(hidari, g.hako.first.x);
        migi = math.max(migi, g.hashi - _sukima);
      }
      if (hidari == double.infinity) continue;
      final double han = math.max(naka - hidari, migi - naka);
      waku.add(
        Rect.fromLTRB(
          math.max(0.0, naka - han - _wakuYohaku),
          k.ue,
          math.min(michiHaba, naka + han + _wakuYohaku),
          k.shita,
        ),
      );
    }

    double takasa = shita;
    for (final _Aida a in aidaList) {
      takasa = math.max(takasa, a.top + a.h);
    }
    takasa += 16;
    return _Haichi(
      gyou,
      aidaList,
      kireme,
      waku,
      seedTop,
      sentouY,
      michiUe,
      michiHaba,
      kakkoX,
      mojiX,
      haba,
      takasa,
    );
  }

  /// 押した大学の帯の文(順位・1位との差・前の大学との差)
  String? _oshitaBun(_IchiKukan r) {
    if (_oshita < 0 || _oshita >= r.narabi.length) return null;
    final _IchiDaigaku x = r.narabi[_oshita];
    // スタートは、大学名と目標順位(「青嵐大　目標3位」。2.0.7)
    if (r.kk < 0) {
      final int? t = x.mokuhyou;
      final String mokuhyou = (t == null || t < 0) ? '' : '　目標${t + 1}位${x.op ? '相当' : ''}';
      return '${x.op ? '学連選抜' : x.mei}$mokuhyou';
    }
    final String mae = r.maeBun(_oshita);
    // 順位の後ろに、前の区間からの変化を付ける(「5位(↑3) 青嵐大」「3位相当(↑2) 学連選抜」)
    final String? hm = x.hendouMoji;
    final String henka = hm == null ? '' : '($hm)';
    final int? soutou = x.soutouJuni;
    final String mei = x.op
        ? (soutou == null ? '学連選抜(OP)' : '${soutou + 1}位相当$henka 学連選抜')
        : '${x.juni + 1}位$henka ${x.mei}';
    // 1位との差か、目標順位との差(差の基準。2.0.7)
    final String sa = _mokuhyouKijun ? r.mokuhyouBun(x) : r.saBun(x);
    return mae.isEmpty ? '$mei　$sa' : '$mei　$sa　$mae';
  }

  @override
  Widget build(BuildContext context) {
    final _IchiKankei? b = _b;
    _IchiKukan? r;
    // 推移(2.1.1)は、区間の途中の位置関係(前の区間の終了時点とこの区間の終了時点をつないだもの)を描く
    final bool suii = _hyouji == 4 && b != null && _suiiDekiru(b, _suiiKukan);
    if (b != null) {
      r = suii
          ? _suiiZu(b, _suiiKukan, _suiiKomaBan / _suiiKomaSuu)
          : b.kukan[_erabu.clamp(0, b.kukan.length - 1)];
    }
    final _IchiKukan? r0 = r;
    _suiiShotenI = (suii && r0 != null) ? _suiiShotenBan(r0) : -1;
    final String? oshitaBun = r0 == null ? null : _oshitaBun(r0);
    final _IchiDaigaku? x0 = (r0 != null && _oshita >= 0 && _oshita < r0.narabi.length)
        ? r0.narabi[_oshita]
        : null;
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          '情報集約パネル',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: (b == null || r0 == null)
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '駅伝の結果がありません。',
                    style: TextStyle(color: HENSUU.textcolor),
                  ),
                ),
              )
            // 上のバーを除いた高さを、上の固定の部分は3割まで、押した大学の帯は4割5分までにし、
            // 道にはいつも4分の1以上を残す(小さいスマホで文字を大きくしても、道が消えて四角を押せなくならないように。2.0.7)
            : LayoutBuilder(
                builder: (context, constraints) {
                  final double takasa = constraints.maxHeight;
                  // 道が見えている高さ(上に固定する部分と区切りの線を除く。押した大学の帯の分は引かない。
                  // 固定する部分は描いたあとに測り、測る前は2割と見込む。2.1.0)
                  final double michiTakasa =
                      math.max(100.0, takasa - (_koteiTakasa ?? takasa * 0.2) - 1);
                  WidgetsBinding.instance.addPostFrameCallback((_) => _koteiHakaru());
                  // 表示の倍率(おまかせは、道が見えている高さで決める。2.1.0)
                  // (推移は、おまかせのときは×4のまま動かさない。2.1.1)
                  final int dan = _omakase
                      ? (suii ? _omakaseSaitei : _omakaseDan(r0, michiTakasa))
                      : _dan.clamp(0, _bairitsu.length - 1);
                  return Column(
                    children: [
                      // 上に固定する部分(区間の切り替えと、倍率のボタン・縮尺の棒)。
                      // 3割まで(超えるときは、この中だけでスクロールする)
                      ConstrainedBox(
                        key: _koteiKey,
                        constraints: BoxConstraints(maxHeight: takasa * 0.3),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          child: _buildKotei(b, dan, suiiR: suii ? r0 : null),
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white24),
                      // 通過順位速報・個人順位速報(2.0.8)。推移(2.1.1)は位置と同じく道を出す
                      if (_hyouji != 0 && _hyouji != 4)
                        Expanded(child: _buildSokuhou(r0))
                      else ...[
                        // 縦が長くなるので、右端につまんで動かせるスクロールバーを出す(2.1.0。
                        // デスクトップで自動のスクロールバーと二重にならないように、自動のほうは止める。
                        // 黒い背景で見えるように、つまみは白っぽい色にする(_shiroScrollbar))
                        Expanded(
                          // 推移で再生しているときに、指で道を動かしたら止める(2.1.1。焦点を追う動きと取り合わないように)
                          child: NotificationListener<ScrollStartNotification>(
                            onNotification: (ScrollStartNotification n) {
                              if (_hyouji == 4 && _saisei && n.dragDetails != null) _suiiTomeru();
                              return false;
                            },
                            child: _shiroScrollbar(
                              controller: _michiScroll,
                              thickness: 10,
                              child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                                child: SingleChildScrollView(
                                  controller: _michiScroll,
                                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                                  child: _buildHontai(context, b, r0, dan, michiTakasa),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 押した大学の帯(4割5分まで。道をスクロールしていても見えるように、道の下(画面の一番下)に置く)
                        // (推移では出さない。2.1.1)
                        if (!suii && oshitaBun != null && x0 != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: takasa * 0.45),
                              child: _buildObi(context, r0, x0, oshitaBun),
                            ),
                          ),
                      ],
                    ],
                  );
                },
              ),
      ),
      // 画面の一番下の「戻る」は、道を広くするためになくした(左上の「←」と、Androidの戻る操作で閉じる。2.0.7)
    );
  }

  /// 押した大学の帯(順位と差。押すたびに、走った選手の説明文、次の区間を走る選手と進む。2.0.7)
  /// ・一番上の行(差の基準と、閉じる「×」)は固定し、その下(差の文・説明文や次の区間を走る選手・案内)は、
  ///   まとめて帯の中でスクロールする(帯の高さは置く側で抑える)
  /// ・「×」は、何かの理由で道が見えなくなっても帯を閉じられるようにするため
  Widget _buildObi(
    BuildContext context,
    _IchiKukan r0,
    _IchiDaigaku x0,
    String oshitaBun,
  ) {
    // 2回目に押したときの、走った選手の持ちタイムの表と能力(説明文の下に出す。2.1.0)
    final Widget? hashittaNaiyou = _hiraki == 1
        ? _kirokuToNouryoku(s: x0.senshu, g: x0.gSenshu, kukanIdx: r0.kk, kirokuAnka: false)
        : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 2, 2, 8),
      decoration: BoxDecoration(
        border: Border.all(color: _iro.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // 差の基準(1位との差か、目標順位との差か。スタートは差がないので出さない)
              Expanded(
                child: r0.kk < 0
                    ? const SizedBox.shrink()
                    : Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('差の基準', style: _chiisai),
                    _komaBotan(
                      'トップ',
                      !_mokuhyouKijun,
                      () => setState(() => _mokuhyouKijun = false),
                    ),
                    _komaBotan(
                      '目標順位',
                      _mokuhyouKijun,
                      () => setState(() => _mokuhyouKijun = true),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _oshita = -1;
                  _hiraki = 0;
                }),
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                tooltip: '閉じる',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // ここから下は、まとめて帯の中でスクロールする
          // (デスクトップで自動のスクロールバーと二重にならないように、自動のほうは止める)
          // (2.1.0から、黒い背景で見えるように、道のスクロールバーと同じ白っぽいつまみにする)
          Flexible(
            child: _shiroScrollbar(
              controller: _setsumeiScroll,
              thickness: 6,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  controller: _setsumeiScroll,
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    key: _obiNakaKey,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        oshitaBun,
                        style: const TextStyle(color: HENSUU.textcolor, fontSize: 13),
                      ),
                      if (_hiraki == 1) ...[
                        const Divider(height: 12, color: Colors.white24),
                        // 走った選手の行と、区間配置確認と同じ「詳細」(選手の詳細の画面を開く)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _senshuGyou(r0, x0),
                                style: const TextStyle(color: Colors.yellowAccent, fontSize: 13),
                              ),
                            ),
                            if (x0.shousaiId != null)
                              TextButton(
                                onPressed: () => senshuShousaiHiraku(context, x0.shousaiId!),
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  '詳細',
                                  style: TextStyle(color: HENSUU.LinkColor, fontSize: 15),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          x0.setsumei ?? '説明文はありません',
                          // ほかの大学に切り替えたときに、同じ高さに来るようにする目印
                          key: _ankaKey,
                          style: TextStyle(
                            color: HENSUU.textcolor.withOpacity(0.9),
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                        // 走った選手の持ちタイムの表と能力(3回目の次の区間を走る選手と同じ並び。2.1.0)
                        if (hashittaNaiyou != null) ...[
                          const Divider(height: 12, color: Colors.white24),
                          hashittaNaiyou,
                        ],
                      ],
                      // 次の区間を走る選手(区間配置確認のカードの上の行と、持ちタイムの表と能力。2.1.0)
                      if (_hiraki == 2) ...[
                        const Divider(height: 12, color: Colors.white24),
                        Text(r0.kk < 0 ? '1区を走る選手' : '次の区間を走る選手', style: _chiisai),
                        const SizedBox(height: 2),
                        _tsugiPanel(context, r0, x0),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        _hiraki == 0
                            ? 'もう一度押すと、走った選手の説明文が出ます'
                            : (_hiraki == 1 && _tsugiDaseru(x0)
                                  ? 'もう一度押すと、次の区間を走る選手が出ます'
                                  : 'もう一度押すと閉じます'),
                        style: _chiisai,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 小さなボタン(区間の切り替えと同じ形。[onTap] がnullなら押せない)
  Widget _komaBotan(String moji, bool on, VoidCallback? onTap) {
    final Color iro = onTap == null ? Colors.white24 : (on ? _iro : Colors.white70);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: on ? _iro.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: on ? _iro : Colors.white24),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(moji, style: TextStyle(color: iro, fontSize: 13)),
      ),
    );
  }

  /// 縮尺の棒(棒が短すぎず長すぎない、区切りのよい距離を選ぶ)
  Widget _shukushaku(double px) {
    int m = 2000;
    for (final int c in const [10, 20, 50, 100, 200, 500, 1000, 2000]) {
      if (c * px >= 40) {
        m = c;
        break;
      }
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: m * px, height: 3, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          m < 1000 ? '${m}m' : '${m ~/ 1000}km',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  /// 区間を切り替える(押した大学の帯は閉じる。覚えない)
  void _kukanKaeru(int i) {
    setState(() {
      _erabu = i;
      _oshita = -1;
      _hiraki = 0;
    });
  }

  /// 区間を1つずつ動かす矢印([onTap] がnullなら、薄くして押せない。2.0.7)
  Widget _yajirushi(IconData icon, String setsumei, VoidCallback? onTap) {
    final bool dekiru = onTap != null;
    return Semantics(
      button: true,
      label: setsumei,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: dekiru ? _iro.withOpacity(0.6) : Colors.white24),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Icon(icon, size: 22, color: dekiru ? _iro : Colors.white24),
          ),
        ),
      ),
    );
  }

  /// 上に固定する部分(区間の切り替えと、倍率のボタン・縮尺の棒)
  /// 区間は「‹」「›」で1つずつ、真ん中を押して出る一覧で好きな区間に切り替える(区間が多くても1行。2.0.7)
  /// 推移(2.1.1)のときは[suiiR]に今の図を渡す(区間を選ぶ欄を推移の区間にし、倍率の行の代わりに再生の行を出す)
  Widget _buildKotei(_IchiKankei b, int dan, {_IchiKukan? suiiR}) {
    final int erabu = _erabu.clamp(0, b.kukan.length - 1);
    final _IchiKukan? sr = _hyouji == 4 ? suiiR : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 配置(区間配置確認)のときは大学を選び、ほかのときは区間を選ぶ(2.0.9)。
            // 推移のときは、推移で見られる区間(2区から)を選ぶ(2.1.1)
            if (_hyouji == 3)
              ..._daigakuErabi(b)
            else if (sr != null)
              ..._suiiKukanErabi(b)
            else ...[
            _yajirushi(
              Icons.chevron_left,
              '前の区間',
              erabu > 0 ? () => _kukanKaeru(erabu - 1) : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PopupMenuButton<int>(
                tooltip: '区間を選ぶ',
                initialValue: erabu,
                color: const Color(0xFF2A2A2A),
                onSelected: _kukanKaeru,
                itemBuilder: (context) => [
                  for (int i = 0; i < b.kukan.length; i++)
                    PopupMenuItem<int>(
                      value: i,
                      child: Text(
                        _kukanMei(b.kukan[i]),
                        style: TextStyle(color: i == erabu ? _iro : HENSUU.textcolor),
                      ),
                    ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _iro.withOpacity(0.15),
                    border: Border.all(color: _iro),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _kukanMei(b.kukan[erabu]),
                          style: const TextStyle(
                            color: _iro,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: _iro, size: 22),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _yajirushi(
              Icons.chevron_right,
              '次の区間',
              erabu < b.kukan.length - 1 ? () => _kukanKaeru(erabu + 1) : null,
            ),
            ],
            // 表示の切り替え(2.0.8。2.0.9からスタートしかないときも出す)
            const SizedBox(width: 8),
            _hyoujiBotan(b),
          ],
        ),
        // 表示の倍率(「−」「＋」と、おまかせ。覚えない)と縮尺の棒(位置のときだけ。2.0.8)
        if (_hyouji == 0) ...[
          const SizedBox(height: 8),
          Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _komaBotan(
              '−',
              false,
              dan > 0
                  ? () => setState(() {
                      _omakase = false;
                      _dan = dan - 1;
                    })
                  : null,
            ),
            Text(
              _bairitsuMei[dan],
              style: const TextStyle(
                color: HENSUU.textcolor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            _komaBotan(
              '＋',
              false,
              dan < _bairitsu.length - 1
                  ? () => setState(() {
                      _omakase = false;
                      _dan = dan + 1;
                    })
                  : null,
            ),
            // おまかせに戻す(2.0.8〜2.0.9は、おまかせのときに押すと「おまかせ ↔」と入れ替わった。2.1.0でなくした)
            _komaBotan(
              'おまかせ',
              _omakase,
              () => setState(() => _omakase = true),
            ),
            _shukushaku(_bairitsu[dan]),
          ],
        ),
        ],
        // 推移の再生の行(最初から・1コマ戻る・再生・1コマ進む・速さ・焦点・倍率。文字を大きくしたら折り返す)と、
        // 区間の中の進み具合の丸(2.1.1)
        if (sr != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _suiiBotan(
                setsumei: '最初から再生する',
                mae: Icons.skip_previous,
                moji: '最初から',
                onTap: _suiiSaishoKara,
              ),
              _suiiBotan(
                setsumei: '1コマ戻る',
                mae: Icons.chevron_left,
                moji: '1コマ',
                onTap: _suiiSaisho(b) ? null : () => _suiiKomaOkuri(false),
              ),
              _suiiBotan(
                setsumei: _saisei ? '止める' : '再生する',
                mae: _saisei ? Icons.pause : Icons.play_arrow,
                moji: _saisei ? '停止' : '再生',
                onTap: _saisei ? _suiiTomeru : _suiiSaisei,
                nuri: true,
              ),
              _suiiBotan(
                setsumei: '1コマ進む',
                moji: '1コマ',
                ato: Icons.chevron_right,
                onTap: _suiiSaigo(b) ? null : () => _suiiKomaOkuri(true),
              ),
              _komaBotan(
                _suiiHayasaMei[_suiiHayasaBan.clamp(0, _suiiHayasaMei.length - 1)],
                false,
                () => setState(() => _suiiHayasaBan = (_suiiHayasaBan + 1) % _suiiKomaMs.length),
              ),
              _suiiShotenBotan(b, sr),
              _komaBotan(
                '−',
                false,
                dan > 0
                    ? () => setState(() {
                        _omakase = false;
                        _dan = dan - 1;
                        _suiiOuYoyaku = true;
                      })
                    : null,
              ),
              Text(
                _bairitsuMei[dan],
                style: const TextStyle(
                  color: HENSUU.textcolor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _komaBotan(
                '＋',
                false,
                dan < _bairitsu.length - 1
                    ? () => setState(() {
                        _omakase = false;
                        _dan = dan + 1;
                        _suiiOuYoyaku = true;
                      })
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 区間の中の進み具合(5つの丸。区間の始めは全部白、中継所は全部黒。数字は出さない。地点は推定なので)
          Semantics(
            label: '区間の中のコマ ${_suiiKomaBan.clamp(0, _suiiKomaSuu)}/$_suiiKomaSuu',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int j = 0; j < _suiiKomaSuu; j++)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: j < _suiiKomaBan ? Colors.white70 : Colors.transparent,
                      border: Border.all(color: Colors.white54),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 推移の区間を選ぶ欄(区間を選ぶ欄と同じ形。区間名と区間の距離。2.1.1)
  List<Widget> _suiiKukanErabi(_IchiKankei b) {
    final List<int> kouho = _suiiKouho(b);
    final int ki = kouho.indexOf(_suiiKukan);
    return [
      _yajirushi(
        Icons.chevron_left,
        '前の区間',
        ki > 0 ? () => _suiiKukanKaeru(kouho[ki - 1]) : null,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: PopupMenuButton<int>(
          tooltip: '区間を選ぶ',
          initialValue: _suiiKukan,
          color: const Color(0xFF2A2A2A),
          onSelected: _suiiKukanKaeru,
          itemBuilder: (context) => [
            for (final int i in kouho)
              PopupMenuItem<int>(
                value: i,
                child: Text(
                  _suiiKukanMei(b, i),
                  style: TextStyle(color: i == _suiiKukan ? _iro : HENSUU.textcolor),
                ),
              ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: _iro.withOpacity(0.15),
              border: Border.all(color: _iro),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _suiiDekiru(b, _suiiKukan) ? _suiiKukanMei(b, _suiiKukan) : '',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _iro,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: _iro, size: 22),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      _yajirushi(
        Icons.chevron_right,
        '次の区間',
        (ki >= 0 && ki < kouho.length - 1) ? () => _suiiKukanKaeru(kouho[ki + 1]) : null,
      ),
    ];
  }

  /// 推移の小さなボタン(「最初から」「1コマ」「再生」「停止」。[mae]・[ato] は文字の前・後ろのアイコン。
  /// [onTap] がnullなら薄くして押せない。[nuri] は塗る(再生・停止)。2.1.1)
  Widget _suiiBotan({
    required String setsumei,
    required String moji,
    IconData? mae,
    IconData? ato,
    VoidCallback? onTap,
    bool nuri = false,
  }) {
    final Color iro = onTap == null ? Colors.white24 : _iro;
    return Semantics(
      button: true,
      label: setsumei,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (nuri && onTap != null) ? _iro.withOpacity(0.2) : Colors.transparent,
            border: Border.all(color: iro),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mae != null) Icon(mae, color: iro, size: 18),
              if (mae != null) const SizedBox(width: 2),
              Text(moji, style: TextStyle(color: iro, fontSize: 13)),
              if (ato != null) const SizedBox(width: 2),
              if (ato != null) Icon(ato, color: iro, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  /// 推移の焦点を選ぶボタン(順位で追うか、大学で追うか。シード権の最後の順位には「(シード権ライン)」。2.1.1)
  Widget _suiiShotenBotan(_IchiKankei b, _IchiKukan r) {
    final int n = r.narabi.where((x) => !x.op).length;
    final int? seed = (b.seed != null && n > b.seed!) ? b.seed : null;
    // シード権の最後の順位(0が1位。ないときは-1)
    final int seedSaigo = seed == null ? -1 : seed - 1;
    String juniMei(int j) => '${j + 1}位${j == seedSaigo ? '(シード権ライン)' : ''}';
    // 大学は大学idの順(学連選抜は最後)
    final List<_IchiDaigaku> daigaku = List<_IchiDaigaku>.of(r.narabi)
      ..sort((a, c) {
        if (a.op != c.op) return a.op ? 1 : -1;
        return (a.univId ?? 0).compareTo(c.univId ?? 0);
      });
    String daigakuMeiYomu(_IchiDaigaku x) => x.op ? '学連選抜' : x.mei;
    String ima = '';
    if (_shotenJuniMode) {
      if (n > 0) ima = juniMei(_shotenJuni.clamp(0, n - 1));
    } else {
      final int i = r.narabi.indexWhere((x) => _daigakuKagi(x) == _shotenKagi);
      if (i >= 0) ima = daigakuMeiYomu(r.narabi[i]);
    }
    const TextStyle midashi = TextStyle(color: Colors.white54, fontSize: 12);
    return PopupMenuButton<String>(
      tooltip: '焦点を選ぶ',
      color: const Color(0xFF2A2A2A),
      onSelected: (String v) {
        setState(() {
          if (v.startsWith('j')) {
            _shotenJuniMode = true;
            _shotenJuni = int.tryParse(v.substring(1)) ?? 0;
          } else {
            _shotenJuniMode = false;
            _shotenKagi = int.tryParse(v.substring(1)) ?? -2;
          }
          _suiiOuYoyaku = true;
        });
        // 道を先に動かす(描いたあとに動かすと、一瞬だけ残像のように見えるため。2.1.1)
        _suiiSakiniOu();
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(enabled: false, child: Text('順位で追う', style: midashi)),
        for (int j = 0; j < n; j++)
          PopupMenuItem<String>(
            value: 'j$j',
            child: Text(
              juniMei(j),
              style: TextStyle(
                color: (_shotenJuniMode && _shotenJuni == j) ? _iro : HENSUU.textcolor,
              ),
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(enabled: false, child: Text('大学で追う', style: midashi)),
        for (final _IchiDaigaku x in daigaku)
          PopupMenuItem<String>(
            value: 'u${_daigakuKagi(x)}',
            child: Text(
              daigakuMeiYomu(x),
              style: TextStyle(
                color: (!_shotenJuniMode && _shotenKagi == _daigakuKagi(x)) ? _iro : HENSUU.textcolor,
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('焦点: $ima ▾', style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ),
    );
  }

  /// 次の表示(位置 → 通過 → 個人 → 配置 → 推移 → 位置。スタートしかないときは、位置 → 配置 → 位置。2.0.9。
  /// 推移は2.1.1。1区終了時点から再生するので、2区が終わるまでは入れない)
  int _tsugiHyouji(_IchiKankei b) {
    if (!b.kukan.any((x) => x.kk >= 0)) return _hyouji == 3 ? 0 : 3;
    final int tsugi = (_hyouji + 1) % 5;
    if (tsugi == 4 && _suiiKouho(b).isEmpty) return 0;
    return tsugi;
  }

  /// 表示を切り替えるボタン(押すたびに「位置」→「通過」→「個人」→「配置」→「位置」。今の表示の名前を出す。
  /// 2.0.8。配置は2.0.9)
  Widget _hyoujiBotan(_IchiKankei b) {
    const List<String> mei = ['位置', '通過', '個人', '配置', '推移'];
    const Color iro = Colors.amberAccent;
    return Semantics(
      button: true,
      label: '表示の切り替え',
      child: Material(
        color: iro.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: iro, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() {
            final int mae = _hyouji;
            _hyouji = _tsugiHyouji(b);
            // 推移を閉じるときは再生を止め、位置では推移で見ていた区間を出す。推移を開くときは区間と焦点を決める(2.1.1)
            if (mae == 4 && _hyouji != 4) _suiiTojiru(b);
            if (_hyouji == 4 && mae != 4) _suiiHiraku(b);
            // 押した大学の帯は閉じる
            _oshita = -1;
            _hiraki = 0;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mei[_hyouji.clamp(0, mei.length - 1)],
                  style: const TextStyle(
                    color: iro,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.sync, color: iro, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 配置(区間配置確認)で見ている大学(最初は自分の大学。学連選抜の監督の年は学連選抜。
  /// 自分の大学が出ていない年は、ID順の最初の大学。2.0.9)
  int _haichiUnivIma(_IchiKankei b) {
    final List<({int id, String mei})> l = b.haichiDaigaku;
    final int? erabi = _haichiUniv;
    if (erabi != null && l.any((x) => x.id == erabi)) return erabi;
    if (b.gakurenJibun && l.any((x) => x.id == kukanHaitiGakurenId)) {
      return kukanHaitiGakurenId;
    }
    final int? my = _gh?.MYunivid;
    if (my != null && l.any((x) => x.id == my)) return my;
    return l.isEmpty ? (my ?? 0) : l.first.id;
  }

  /// 大学を選ぶ欄(配置のとき。「‹」「›」は端まで行くと反対の端に回る(区間配置確認と同じ)。
  /// 大学名は1行に収め、入りきらないところは「…」で省く。一覧の中では全部出す。2.0.9)
  List<Widget> _daigakuErabi(_IchiKankei b) {
    final List<({int id, String mei})> l = b.haichiDaigaku;
    final int ima = _haichiUnivIma(b);
    final int i = l.indexWhere((x) => x.id == ima);
    void kaeru(int j) => setState(() => _haichiUniv = l[j].id);
    return [
      _yajirushi(
        Icons.chevron_left,
        '前の大学',
        l.length > 1 ? () => kaeru(i <= 0 ? l.length - 1 : i - 1) : null,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: PopupMenuButton<int>(
          tooltip: '大学を選ぶ',
          initialValue: ima,
          color: const Color(0xFF2A2A2A),
          onSelected: (id) => setState(() => _haichiUniv = id),
          itemBuilder: (context) => [
            for (final ({int id, String mei}) x in l)
              PopupMenuItem<int>(
                value: x.id,
                child: Text(
                  x.mei,
                  style: TextStyle(color: x.id == ima ? _iro : HENSUU.textcolor),
                ),
              ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: _iro.withOpacity(0.15),
              border: Border.all(color: _iro),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    i >= 0 ? l[i].mei : '',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _iro,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: _iro, size: 22),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      _yajirushi(
        Icons.chevron_right,
        '次の大学',
        l.length > 1 ? () => kaeru(i < 0 || i >= l.length - 1 ? 0 : i + 1) : null,
      ),
    ];
  }

  /// 通過順位速報・個人順位速報(今の速報の画面を、上のバーと下の「前・次」を外して入れる。
  /// 区間はパネルで選んだ区間。個人順位速報は、レースの途中は途中用、結果画面では結果画面用。2.0.8)
  Widget _buildSokuhou(_IchiKukan r) {
    // 配置(区間配置確認。区間に関係なく、パネルで選んだ大学。2.0.9)
    if (_hyouji == 3) {
      final _IchiKankei? b = _b;
      return ModalKukanHaitiView(
        targetUnivid: _gh?.MYunivid ?? 0,
        univid: b == null ? null : _haichiUnivIma(b),
        umekomi: true,
      );
    }
    if (r.kk < 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'スタート前なので、通過順位と個人順位はまだありません。',
            style: TextStyle(color: HENSUU.textcolor),
          ),
        ),
      );
    }
    if (_hyouji == 1) {
      return ModalKukanResultListViewPass(umekomi: true, kukan: r.kk);
    }
    return widget.made == null
        ? ModalKukanResultListView(umekomi: true, kukan: r.kk)
        : ModalKukanResultListView350(umekomi: true, kukan: r.kk);
  }

  /// スクロールする部分(説明の文と、道と大学名の四角。道の部分は横にもスクロールする)
  Widget _buildHontai(
    BuildContext context,
    _IchiKankei b,
    _IchiKukan r,
    int dan,
    double gamenTakasa,
  ) {
    const TextStyle setsumei = TextStyle(color: Colors.white70, fontSize: 12, height: 1.5);
    final double px = _bairitsu[dan];
    return Column(
      // 推移(2.1.1)は、焦点の大学まで道を動かすときに、道の上端の高さを測る
      key: r.suii ? _suiiNakaKey : null,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 説明の文は短くする(おまかせと集団の説明は、説明書に書く)
        if (r.suii) ...[
          // 推移(2.1.1。つないだ動きだと分かるように。地点は出さない)
          const Text('中継所ごとの位置関係を、区間を5つに分けてつないだコマ送りです。', style: setsumei),
          if (r.kk == 0)
            const Text('1区は、飛び出した選手と集団の記録をもとにした演出です。', style: setsumei),
          const Text('水色の枠: 焦点の大学(大学の四角を押すと、その大学を追います)。', style: setsumei),
        ] else if (r.kk < 0)
          const Text('スタート前の並びです(大学のID順)。', style: setsumei)
        else ...[
          Text(
            '${r.kk + 1}区終了時点のタイム差を、区間の平均の速さで距離に換算した位置関係の図です。',
            style: setsumei,
          ),
          const Text('右の括弧は前の大学との間です(点線は途中を省略した間)。', style: setsumei),
        ],
        if (r.narabi.any((x) => x.jibun))
          const Text('オレンジの枠: あなたの大学', style: setsumei),
        if (b.opAri)
          Text(
            b.gakurenJibun
                ? 'オレンジの点線の枠: 学連選抜(あなたが監督。順位に数えない)'
                : '点線の枠: 学連選抜(順位に数えない)',
            style: setsumei,
          ),
        if (!r.suii)
          Text(
            r.kk < 0
                ? '大学の四角を押すと、下に1区を走る選手が出ます。'
                : (r.kk + 1 < b.zenKukansuu
                      ? '大学の四角を押すと下に差が、もう一度押すと走った選手の説明文、さらに押すと次の区間を走る選手が出ます。'
                      : '大学の四角を押すと下に差が、もう一度押すと走った選手の説明文が出ます。'),
            style: setsumei,
          ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            final TextScaler scaler = MediaQuery.textScalerOf(context);
            // 集団の1行には、画面の幅に入るだけ並べる(2.1.0。_haichi の中で行ごとに決める)
            // (推移は途中を省略しない。省略が出たり消えたりして道が跳ねないように。2.1.1)
            final _Haichi h = _haichi(b, r, w, scaler, px, r.suii ? double.infinity : gamenTakasa);
            // 推移は、焦点の大学の四角の真ん中の高さを覚え、描いたあとに道を動かす(2.1.1)
            if (r.suii) {
              // 次のコマを先に計算するときに使う(_suiiSakiniOu)
              _suiiMaeHaba = w;
              _suiiMaeScaler = scaler;
              _suiiMaePx = px;
              double? y;
              for (final _Gyou g in h.gyou) {
                for (final _Hako hk in g.hako) {
                  if (hk.i == _suiiShotenI) y = g.y + g.h / 2;
                }
              }
              _suiiShotenY = y;
              WidgetsBinding.instance.addPostFrameCallback((_) => _suiiOu());
            }
            // 道と四角と差の部分は、画面より広いときは横にもスクロールする(文は折り返さない)
            final Widget michi = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                key: r.suii ? _suiiMichiKey : null,
                width: h.haba,
                height: h.takasa,
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _MichiPainter(h))),
                    // 前の大学(集団)との間の距離と秒差(括弧の真ん中。2.1.0から距離と秒差の2行。詰めた間は括弧が点線)
                    for (final _Aida a in h.aida)
                      Positioned(
                        left: h.mojiX,
                        top: a.top,
                        child: Text(a.moji, style: _migiStyle, softWrap: false),
                      ),
                    // シード権ライン(2.1.0から、道の帯の上だけに引く。右の括弧と差の文には重ならない。
                    // 文字を大きくして文が道の帯より長くなっても、はみ出さないように後ろを切る)
                    if (h.seedTop != null)
                      Positioned(
                        left: 0,
                        top: h.seedTop!,
                        width: h.michiHaba,
                        child: Row(
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: h.michiHaba * 0.7),
                              child: const Text(
                                'シード権ライン',
                                style: _seedMojiStyle,
                                softWrap: false,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: SizedBox(
                                height: 8,
                                child: CustomPaint(painter: _TensenPainter()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // 集団の中で、先頭から遅れた秒の行の右の「+1秒」(2.1.0)
                    for (final _Gyou g in h.gyou)
                      if (g.byou != null)
                        Positioned(
                          left: g.byouX,
                          top: g.y,
                          height: g.h,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: 1,
                            child: Text(g.byou!, style: _chiisai, softWrap: false),
                          ),
                        ),
                    // 大学の四角(推移もすべらせず、コマごとに切り替える。2.1.1の開発中は短くすべらせていたが、
                    // 電池を使うのでやめた)
                    for (final _Gyou g in h.gyou)
                      for (final _Hako hk in g.hako)
                        Positioned(
                          left: hk.x,
                          top: g.y + (g.h - hk.h) / 2,
                          width: hk.w,
                          height: hk.h,
                          child: _hakoWidget(b, r, hk, scaler),
                        ),
                  ],
                ),
              ),
            );
            return michi;
          },
        ),
      ],
    );
  }

  /// 大学の四角(押すと、画面の下に差を出す。押すたびに、走った選手の説明文、次の区間を走る選手と進み、
  /// その次に押すと消す。2.0.7)
  Widget _hakoWidget(_IchiKankei b, _IchiKukan r, _Hako hk, TextScaler scaler) {
    final _IchiDaigaku x = r.narabi[hk.i];
    final bool orange = x.jibun || (b.gakurenJibun && x.op);
    // 推移(2.1.1)は、焦点の大学を水色の枠にする
    final bool erabareta = r.suii ? hk.i == _suiiShotenI : _oshita == hk.i;
    final bool ichii = r.kk >= 0 && identical(x, r.top);
    final Color wakuIro = erabareta
        ? _iro
        : (orange ? _jibunIro : (ichii ? Colors.white : Colors.white38));
    final double futosa = (erabareta || orange || ichii) ? _wakuSaidai : 1;
    // 学連選抜は点線の枠(押したときは水色の線の枠)
    final bool tensen = x.op && !erabareta;
    Widget naka = Container(
      padding: const EdgeInsets.symmetric(horizontal: _hakoYoko, vertical: _hakoTate),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        border: tensen ? null : Border.all(color: wakuIro, width: futosa),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      child: _hakoNaka(r, hk.i, scaler),
    );
    if (tensen) {
      naka = CustomPaint(
        foregroundPainter: _TensenWakuPainter(orange ? _jibunIro : Colors.white),
        child: naka,
      );
    }
    final Widget hako = GestureDetector(
      // 押した四角は、下の帯が伸びて隠れるときに見えるようにするため、印を付けておく(推移では使わない)
      key: (!r.suii && erabareta) ? _oshitaKey : null,
      behavior: HitTestBehavior.opaque,
      // 推移(2.1.1)は、押した大学に焦点を移す(下の帯は出さない)
      onTap: () => r.suii ? _suiiShotenErabu(x) : _hakoOsu(r, hk.i),
      child: naka,
    );
    return hako;
  }
}

/// 点線で線を引く(パスに沿って、4px引いて3px空ける)
void _tensenDeHiku(Canvas canvas, Path path, Paint p) {
  for (final metric in path.computeMetrics()) {
    double d = 0;
    while (d < metric.length) {
      canvas.drawPath(metric.extractPath(d, math.min(d + 4, metric.length)), p);
      d += 7;
    }
  }
}

/// 道の帯・切れ目の印・いちばん前の線・間の括弧
class _MichiPainter extends CustomPainter {
  final _Haichi h;

  _MichiPainter(this.h);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint michi = Paint()..color = _michiIro;
    final double shita = size.height - 6;
    // 道の帯(詰めた間の真ん中は空ける)
    double y = h.michiUe;
    for (final k in h.kireme) {
      final double m = (k.y0 + k.y1) / 2;
      if (m - 5 > y) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTRB(0, y, h.michiHaba, m - 5), const Radius.circular(6)),
          michi,
        );
      }
      y = m + 5;
    }
    if (shita > y) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(0, y, h.michiHaba, shita), const Radius.circular(6)),
        michi,
      );
    }
    // 切れ目の印(帯の切れ目の上下に点線)
    final Paint kiremeSen = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1;
    for (final k in h.kireme) {
      final double m = (k.y0 + k.y1) / 2;
      for (double x = 0; x < h.michiHaba; x += 6) {
        final double x2 = math.min(x + 3, h.michiHaba);
        canvas.drawLine(Offset(x, m - 5), Offset(x2, m - 5), kiremeSen);
        canvas.drawLine(Offset(x, m + 5), Offset(x2, m + 5), kiremeSen);
      }
    }
    // 2校以上の集団を囲む枠(薄い線と、ほんの少し明るい塗り)
    final Paint wakuNuri = Paint()..color = const Color(0x12FFFFFF);
    final Paint wakuSen = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final Rect rc in h.waku) {
      final RRect rr = RRect.fromRectAndRadius(rc, const Radius.circular(8));
      canvas.drawRRect(rr, wakuNuri);
      canvas.drawRRect(rr, wakuSen);
    }
    // いちばん前(1位)の線
    canvas.drawLine(
      Offset(0, h.sentouY),
      Offset(h.michiHaba, h.sentouY),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 1.5,
    );
    // 前の大学(集団)との間の括弧(詰めた間は点線)
    final Paint kakko = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final _Aida a in h.aida) {
      final Path path = Path()
        ..moveTo(h.kakkoX, a.y0)
        ..lineTo(h.kakkoX + 8, a.y0)
        ..lineTo(h.kakkoX + 8, a.y1)
        ..lineTo(h.kakkoX, a.y1);
      if (a.tsume) {
        _tensenDeHiku(canvas, path, kakko);
      } else {
        canvas.drawPath(path, kakko);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MichiPainter old) => old.h != h;
}

/// 学連選抜の四角の点線の枠
class _TensenWakuPainter extends CustomPainter {
  final Color iro;

  _TensenWakuPainter(this.iro);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = iro
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final Path waku = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
          const Radius.circular(4),
        ),
      );
    _tensenDeHiku(canvas, waku, p);
  }

  @override
  bool shouldRepaint(covariant _TensenWakuPainter old) => old.iro != iro;
}

/// シード権ラインの点線
class _TensenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = Colors.amberAccent
      ..strokeWidth = 1;
    final double y = size.height / 2;
    for (double x = 0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width), y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _TensenPainter old) => false;
}
