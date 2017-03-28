require 'rexml/document'
require './model/comment'
require './model/tree_tagger'
require 'sanitize'

# 呼びかけ関係(ある人物の名前を含むかどうか)から呼びかけ先のコメント番号を取得するメソッド
def make_links_by_reply(cmts)
  cmts.each do |cmt|
    xml_cmt = REXML::Document.new(cmt.txt.to_s)
    xml_cmt.elements.each('comment/p/a') do |elem|
      if elem.attributes["class"] == "user-hover"
        (0..cmt.id-1).reverse_each do |i|
          if cmts[i].author == elem.attributes["rel"]
            cmt.links.push([i, 1])
            break
          end
        end
      end
    end
  end
end

# 引用関係から引用先のコメント番号を取得するメソッド
# ゴミコードなので説明文を書いておく
# blockquote要素から引用している文を取得できる
# 取得したコメント番号以前で、引用している文を含む最も古い文章を探す
# Sanitizeはhtml, xml要素を綺麗に取り除くための処理であり、自動で半角スペースが入るので修正のためにgsubやstripを使っている
# モンキーパッチを書いてもいいかもしれないね
def make_links_by_quote(cmts)
  cmts.each do |cmt|
    xml_cmt = REXML::Document.new(cmt.txt.to_s)
    xml_cmt.elements.each('comment/blockquote') do |elem|
      (0..cmt.id-1).each do |i|
        if Sanitize.clean(cmts[i].txt).gsub(/\s\s/, " ").strip.include?(Sanitize.clean(elem.elements['p'].text).strip)
          cmt.links.push([i, 2])
          break
        end
      end
    end
  end
end

# 文頭の接続詞から並列するコメントの番号を取得するメソッド
def make_links_by_conjection(cmts)
  cmts.each do |cmt|
    tagger = TreeTagger.new()
    #puts Sanitize.clean(cmt.txt.to_s).strip
    rst = tagger.analysis(Sanitize.clean(cmt.txt.to_s).strip)
    unless rst.empty?
      if rst[0][1] == "IN" || rst[0][1] == "CC"
        (0..cmt.id-1).reverse_each do |i|
          cmt.links.push([i, 3]) if cmt.author == cmts[i].author
          break
        end
      end
    end
  end
end

# 作成されたlinkを整形するメソッド
# 空のものにはdescriptionへのリンクを追加
def finalize_comments(cmts)
  cmts.each do |cmt|
    cmt.links.uniq!
    cmt.links.push(0) if cmt.links.length == 0 && cmt.id != 0
  end
end
