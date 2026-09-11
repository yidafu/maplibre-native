/**
 * MapLibre Native for HarmonyOS
 * Test Page Navigation
 *
 * Sectioned list with search, inspired by Android's FeatureOverviewActivity.
 * Data is sourced from TestPageRegistry to separate concerns.
 */

import { router } from '@kit.ArkUI';
import { TEST_PAGE_CATEGORIES, TestPageCategory, TestPageItem } from './TestPageRegistry';

@Entry
@Component
struct Index {
  @State private categories: TestPageCategory[] = TEST_PAGE_CATEGORIES;
  @State private searchQuery: string = '';
  @State private expandedSections: boolean[] = new Array(TEST_PAGE_CATEGORIES.length).fill(true);

  /**
   * Filter categories and pages by search query.
   */
  get filteredCategories(): TestPageCategory[] {
    const q = this.searchQuery.trim().toLowerCase();
    if (!q) {
      return this.categories;
    }
    return this.categories
      .map((cat: TestPageCategory): TestPageCategory => ({
        name: cat.name,
        key: cat.key,
        pages: cat.pages.filter((p: TestPageItem): boolean =>
          p.title.toLowerCase().includes(q) || p.description.toLowerCase().includes(q)
        ),
      }))
      .filter((cat: TestPageCategory): boolean => cat.pages.length > 0);
  }

  build() {
    Column() {
      // Top bar
      Row() {
        Text('MapLibre Native')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        Text(' 测试')
          .fontSize(20)
          .fontColor(Color.White)
      }
      .width('100%')
      .height(56)
      .backgroundColor('#2196F3')
      .padding({ left: 20 })
      .alignItems(VerticalAlign.Center)

      // Search bar
      Row() {
        TextInput({ placeholder: '搜索测试页面...', text: this.searchQuery })
          .placeholderColor('#999')
          .fontSize(15)
          .height(40)
          .padding({ left: 16 })
          .backgroundColor(Color.White)
          .borderRadius(20)
          .onChange((val: string) => {
            this.searchQuery = val;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .backgroundColor('#F5F5F5')

      // Sectioned list
      List({ space: 0 }) {
        ForEach(this.filteredCategories, (category: TestPageCategory, catIndex: number) => {
          // Section header
          ListItem() {
            this.buildSectionHeader(category, catIndex)
          }

          // Section items (when expanded)
          if (this.expandedSections[catIndex]) {
            ForEach(category.pages, (page: TestPageItem) => {
              ListItem() {
                this.buildPageItem(page)
              }
            })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')

      // Footer
      Row() {
        Text('MapLibre Native v2.0.0')
          .fontSize(12)
          .fontColor('#999')
      }
      .width('100%')
      .height(36)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildSectionHeader(category: TestPageCategory, index: number) {
    Row() {
      Text(category.name)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')

      Blank()

      // Badge
      Text(`${category.pages.length}`)
        .fontSize(12)
        .fontColor('#2196F3')
        .backgroundColor('#E3F2FD')
        .borderRadius(10)
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })

      Text(this.expandedSections[index] ? '▲' : '▼')
        .fontSize(14)
        .fontColor('#999')
        .margin({ left: 8 })
    }
    .width('100%')
    .height(48)
    .padding({ left: 20, right: 20 })
    .backgroundColor('#EDEDED')
    .onClick(() => {
      const toggled = [...this.expandedSections];
      toggled[index] = !toggled[index];
      this.expandedSections = toggled;
    })
  }

  @Builder
  buildPageItem(page: TestPageItem) {
    Row() {
      Column() {
        Text(page.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .width('100%')

        Text(page.description)
          .fontSize(13)
          .fontColor('#888')
          .margin({ top: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(22)
        .fontColor('#CCC')
        .margin({ left: 8 })
    }
    .width('100%')
    .height(64)
    .padding({ left: 20, right: 20 })
    .backgroundColor(Color.White)
    .onClick(() => {
      this.navigateToPage(page.route);
    })
  }

  private navigateToPage(route: string): void {
    router.pushUrl({ url: route })
      .then(() => {
        console.info(`[Index] Navigated to: ${route}`);
      })
      .catch((err: Error) => {
        console.error(`[Index] Navigation failed: ${err.message}`);
      });
  }
}
