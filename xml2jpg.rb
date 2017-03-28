require 'rexml/document'
require 'csv'
require 'gviz'
require 'sanitize'
require './function'
require './model/comment'
require './model/tree_tagger'
require './model/tf_idf'


# xmlファイルを読み込み
if ARGV.empty?
  puts "xmlファイルを実行引数に入力してください"
  exit
end
doc = REXML::Document.new(open(ARGV[0]))


# descriptionの情報を取得
desc = Comment.new
desc.txt    = doc.elements['rss/channel/item/description/p']
desc.id     = 0
desc.author = doc.elements['rss/channel/item/reporter'].to_s.gsub(/(\r\n|\r|\n)/, " ")


# cmts配列にコメントの各要素を格納
# cmts[0]はdescription, cmts[1]以降はコメントが入っている
cmts = []
cmts.push(desc)
doc.elements.each_with_index('rss/channel/item/comments/comment') do |cmt, i|
  c = Comment.new
  c.id     = i+1
  c.author = cmt.attributes["author"]
  c.txt    = cmt.to_s.gsub(/(\r\n|\r|\n)/, " ")
  cmts.push(c)
end

#commentにlinksを挿入
make_links_by_reply(cmts)
make_links_by_quote(cmts)
make_links_by_conjection(cmts)
finalize_comments(cmts)

# テスト用にlinkの中身を描画
# cmts.each do |c|
#   puts "#{c.id} -> #{c.links}"
# end

# tfidf(総文書=全コメント, 文書=コメント)を計算し、特徴語の情報を抽出
tfidf = TfIdf.new(cmts)

# commentに自分のtfidfスコアを教える
cmts.each do |c|
  c.tfidf = tfidf.tfidf[c.id]
  c.set_label
end

cmts.each do |c|
  puts "#{c.id} -> #{c.label}"
end


# グラフ描画
# {ファイル名}.jpegが生成される
# 例: hoge.xml の場合 -> images/hoge.jpeg
file_name = File.basename(ARGV[0], ".*").intern
gv = Gviz.new(file_name)
gv.graph do
  global layout:'dot', label: doc.elements['rss/channel/item/title'].text, rankdir: "BT"
  cmts.reverse_each do |cmt|
    route cmt.id.to_s.intern => cmt.links.map{|l| l[0].to_s.intern}
    node cmt.id.to_s.intern, shape:'record', label: "{##{cmt.id} | {keywords | {#{cmt.get_chacteristic_words}}} }", fontsize: 20, style: 'solid,filled', color:'black', fillcolor:cmt.get_color
#{}"#" + cmt.id.to_s+ "| keywords |"
    # edge属性の変更
    cmt.links.each do |l|
      if l[1] == 1
        # 呼びかけ関係
        edge("#{cmt.id}_#{l[0]}".intern, arrowhead: 'vee')
      elsif l[1] == 2
        # 引用関係
        edge("#{cmt.id}_#{l[0]}".intern, arrowhead: 'box', style: 'bold')
      elsif l[1] == 3
        # 並列関係
        edge("#{cmt.id}_#{l[0]}".intern, arrowhead: 'diamond', style: 'bold')
      end
    end
  end
end

gv.save("image/#{file_name}".intern, :svg)


# 各コメントをテキストファイルで出力
# file_name = File.basename(ARGV[0], ".*").intern
# cmts.each do |c|
#   File.open("#{file_name}/#{format('%02d',c.id)}.txt","wb") {|f|
#     f.write Sanitize.clean(c.txt).lstrip.rstrip
#   }
# end
