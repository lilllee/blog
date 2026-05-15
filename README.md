# junho

내가 쓰는 블로그. 한 폰트, 한 컬러, 660px. 글이 잘 읽히는 것 외에는 별로 신경 쓰지 않았다.

Phoenix + SQLite로 굴러간다. 누가 clone 해서 자기 이름 박고 그대로 써도 무방하다.

## 뭐가 있나

- 글 쓰기 / 임시저장 / 발행, 표지 이미지
- about 페이지 (이력서 비슷한 것, 섹션별로 JSON 편집)
- 한→영/일/중 자동 번역 (Gemini API 키 있을 때만)
- RSS, sitemap, OG 이미지, JSON-LD 같은 SEO 기본기
- `/admin` 은 Basic Auth로 가려둠
- 다크/라이트는 `prefers-color-scheme`만 보고 따라감 (토글 없음)

검색이나 태그 필터, 댓글 같은 건 일부러 안 넣었다. 글 자체에 집중하려고.

## 깔고 돌리기

Elixir 1.14+, Erlang/OTP 가 깔려있다고 가정한다.

```bash
git clone <repo-url>
cd blog

cp .env.example .env
# .env 열어서 BLOG_ADMIN_USER, BLOG_ADMIN_PASS 둘 채우기

mix setup
mix phx.server
```

`http://localhost:4000` — 글 목록.
`http://localhost:4000/admin/posts` — 어드민. Basic Auth 프롬프트가 뜨면 위에서 채운 값으로 로그인.

`.env`는 dev/test에서 `config/runtime.exs`가 알아서 읽는다. prod에서는 진짜 환경변수로 박아넣는다 (컨테이너든, systemd든, fly secrets든).

## 환경변수

`.env.example` 에 다 있는데 요약하면:

**둘 다 필수**
- `BLOG_ADMIN_USER`, `BLOG_ADMIN_PASS` — 어드민 로그인. 안 채우면 `/admin/*` 접근 시 서버가 raise 한다.

**선택**
- `GEMINI_API_KEY` — Google AI Studio 키. 있어야 번역이 켜진다. 없으면 한국어 그대로만 나온다.
- `GEMINI_MODEL` — 기본 `gemini-2.0-flash`.

**prod 전용**
- `SECRET_KEY_BASE` — `mix phx.gen.secret` 으로 만들면 됨.
- `PHX_HOST` — 도메인.
- `PORT`, `DATABASE_PATH`, `POOL_SIZE` — 기본값 있음.

## 자주 쓰는 커맨드

```bash
mix phx.server          # 개발 서버
iex -S mix phx.server   # IEx 같이
mix ecto.migrate
mix ecto.reset          # DB 날리고 다시
mix test
mix format
mix assets.deploy       # tailwind/esbuild + digest
```

## 디렉터리

```
lib/
  blog/              도메인. Note, Resume, Translation, Slug.
  blog_web/
    live/            홈, about, admin/*
    controllers/     RSS/sitemap, 이미지 서빙, note 뷰, 옛 URL 리다이렉트
    components/      core_components (flash만), 레이아웃
    seo.ex
    markdown.ex
assets/
  css/app.css        스타일시트 한 장
  js/app.js          LiveSocket + topbar + locale 저장
priv/repo/migrations/
```

CSS는 한 파일이고, JS도 거의 없다. 페이지를 추가하거나 디자인을 바꿀 일이 있으면 `assets/css/app.css` 하나만 보면 된다.

## 배포

원래는 Fly.io + Litestream으로 돌리고 있다 (`fly.toml`, `litestream.sh` 참고). DB가 SQLite라서 Litestream으로 S3에 stream하면 끝.

다른 데 올려도 상관없다. Elixir release 돌릴 수 있으면 어디든.

```bash
mix assets.deploy
mix release
```

## 라이선스

MIT.
