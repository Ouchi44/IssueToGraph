require "open3"

class TreeTagger
  # 与えられたテキストをTreeTaggerで解析し結果を配列として返却
  def analysis(text)
    command = "echo \"" + text + "\" | tteng"
    out, err, status = Open3.capture3(command)
    out.split(/\t|\n/).each_slice(3).to_a
  end

  def analysis_file(file)
    out, err, status = Open3.capture3("cat #{file} | tteng")
    #puts err unless err.nil?
    out.split(/\t|\n/).each_slice(3).to_a
  end


end
