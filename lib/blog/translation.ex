defmodule Blog.Translation do
  @moduledoc """
  Translation context module - main API for translation functionality.
  """

  alias Blog.Translation.{Translation, Translator}

  defdelegate translate(text, target_lang, source_lang \\ "ko"), to: Translator
  defdelegate translate_post(post, target_lang, source_lang \\ "ko"), to: Translator

  def supported_languages, do: Translation.supported_languages()
  def language_names, do: Translation.language_names()

  def get_language_name(code) do
    Map.get(language_names(), code, code)
  end

  @ui_strings %{
    "ko" => %{
      "blog" => "블로그",
      "about" => "내 정보",
      "search" => "검색",
      "recent_posts" => "최근 글",
      "read_more" => "더 보기",
      "min_read" => "분 소요",
      "prev" => "이전 글",
      "next" => "다음 글",
      "tags" => "태그",
      "published" => "발행일",
      "no_posts" => "글이 없습니다",
      "no_posts_yet" => "아직 작성된 글이 없습니다.",
      "copyright" => "All rights reserved.",
      "all" => "전체",
      "subtitle" => "기록",
      "back_to_list" => "목록으로",
      "series_nav" => "시리즈 탐색",
      "related_posts" => "관련 글",
      "not_found" => "해당 글을 찾을 수 없습니다.",
      "skills" => "기술",
      "experience" => "경력",
      "projects" => "프로젝트",
      "education" => "학력",
      "certifications" => "자격증",
      "spoken_languages" => "언어",
      "interests" => "관심 분야",
      "present" => "현재",
      "currently_employed" => "재직 중"
    },
    "en" => %{
      "blog" => "Blog",
      "about" => "About",
      "search" => "Search",
      "recent_posts" => "Recent Posts",
      "read_more" => "Read more",
      "min_read" => "min read",
      "prev" => "Previous",
      "next" => "Next",
      "tags" => "Tags",
      "published" => "Published",
      "no_posts" => "No posts found",
      "no_posts_yet" => "No posts yet.",
      "copyright" => "All rights reserved.",
      "all" => "All",
      "subtitle" => "Writing about development, life, and thoughts.",
      "back_to_list" => "Back to list",
      "series_nav" => "Series Navigation",
      "related_posts" => "Related Posts",
      "not_found" => "Post not found.",
      "skills" => "Skills",
      "experience" => "Experience",
      "projects" => "Projects",
      "education" => "Education",
      "certifications" => "Certifications",
      "spoken_languages" => "Languages",
      "interests" => "Interests",
      "present" => "Present",
      "currently_employed" => "Currently Employed"
    },
    "ja" => %{
      "blog" => "ブログ",
      "about" => "私について",
      "search" => "検索",
      "recent_posts" => "最近の投稿",
      "read_more" => "続きを読む",
      "min_read" => "分で読める",
      "prev" => "前の記事",
      "next" => "次の記事",
      "tags" => "タグ",
      "published" => "公開日",
      "no_posts" => "記事がありません",
      "no_posts_yet" => "まだ記事がありません。",
      "copyright" => "All rights reserved.",
      "all" => "すべて",
      "subtitle" => "開発、日常、そして考えを記録します。",
      "back_to_list" => "一覧に戻る",
      "series_nav" => "シリーズナビ",
      "related_posts" => "関連記事",
      "not_found" => "記事が見つかりません。",
      "skills" => "スキル",
      "experience" => "経歴",
      "projects" => "プロジェクト",
      "education" => "学歴",
      "certifications" => "資格",
      "spoken_languages" => "言語",
      "interests" => "趣味・関心",
      "present" => "現在",
      "currently_employed" => "在職中"
    },
    "zh" => %{
      "blog" => "博客",
      "about" => "关于我",
      "search" => "搜索",
      "recent_posts" => "最新文章",
      "read_more" => "阅读更多",
      "min_read" => "分钟阅读",
      "prev" => "上一篇",
      "next" => "下一篇",
      "tags" => "标签",
      "published" => "发布日期",
      "no_posts" => "暂无文章",
      "no_posts_yet" => "暂无文章。",
      "copyright" => "版权所有",
      "all" => "全部",
      "subtitle" => "记录开发、生活和思考。",
      "back_to_list" => "返回列表",
      "series_nav" => "系列导航",
      "related_posts" => "相关文章",
      "not_found" => "未找到该文章。",
      "skills" => "技能",
      "experience" => "工作经历",
      "projects" => "项目",
      "education" => "教育背景",
      "certifications" => "资格证书",
      "spoken_languages" => "语言能力",
      "interests" => "兴趣爱好",
      "present" => "至今",
      "currently_employed" => "在职中"
    }
  }

  def t(key, locale \\ "ko") do
    locale_strings = Map.get(@ui_strings, locale, @ui_strings["ko"])
    Map.get(locale_strings, key, key)
  end

  def ui_strings(locale) do
    Map.get(@ui_strings, locale, @ui_strings["ko"])
  end
end
