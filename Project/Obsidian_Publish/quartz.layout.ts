import { PageLayout, SharedLayout } from "./quartz/cfg"
import * as Component from "./quartz/components"

// Obsidian Publish風 3カラムレイアウト設定
// 参照: docs/DD.md セクション2

export const sharedPageComponents: SharedLayout = {
  head: Component.Head(),
  header: [],
  afterBody: [],
  footer: Component.Footer({
    links: {
      GitHub: "https://github.com/your-repo",
    },
  }),
}

export const defaultContentPageLayout: PageLayout = {
  // 左サイドバー
  left: [
    Component.PageTitle(),
    Component.MobileOnly(Component.Spacer()),
    Component.Search(),
    Component.Darkmode(),
    Component.DesktopOnly(Component.Explorer({ title: "Explorer" })),
  ],
  // メインコンテンツ（ヘッダー部分）
  beforeBody: [
    Component.ArticleTitle(),
    Component.ContentMeta(),
    Component.TagList(),
  ],
  // 右サイドバー
  right: [
    Component.Graph({
      localGraph: { depth: 1 },
      globalGraph: { depth: 2 },
    }),
    Component.DesktopOnly(Component.TableOfContents()),
    Component.Backlinks(),
  ],
}

export const defaultListPageLayout: PageLayout = {
  left: [
    Component.PageTitle(),
    Component.MobileOnly(Component.Spacer()),
    Component.Search(),
    Component.Darkmode(),
    Component.DesktopOnly(Component.Explorer({ title: "Explorer" })),
  ],
  beforeBody: [Component.ArticleTitle(), Component.ContentMeta()],
  right: [],
}
