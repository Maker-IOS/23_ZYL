import { permissionManager } from '../../manager'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { JSON } from '@kit.ArkTS'
import { picker } from '@kit.CoreFileKit'
import { dataSharePredicates } from '@kit.ArkData'
import { formatByteLength } from '../../common/utils'
import dayjs from 'dayjs'
import { Prompt } from '@kit.ArkUI'

@Entry
@Component
struct MediaLibraryKitTestPage {
  @State isAuth: boolean = false
  @State photoCount: number = 0
  @State photoAssetUri: string = ''
  @State photoAssetDisplayName: string = ''
  @State photoAssetSize: string = ''
  @State photoAssetDateAdded: string = ''
  @State albumCount: string = ''
  @State albumCoverUri: string = ''
  @State albumName: string = ''

  aboutToAppear(): void {
    this.resquestPermission()
  }

  async resquestPermission() {
    this.isAuth = await permissionManager.requestPermissions([
      'ohos.permission.READ_IMAGEVIDEO',
      'ohos.permission.WRITE_IMAGEVIDEO'
    ])
  }

  build() {
    Navigation() {
      Scroll() {
        Column({ space: 10 }) {
          Text('图库读写是否授权-isAuth ' + this.isAuth)
          Button('使用Picker选择媒体库资源-无需申请权限')
            .onClick(() => {
              // 图库Piker 在应用内打开图库，无需跳转图库
              const photoViewPicker = new photoAccessHelper.PhotoViewPicker();

              // 另一种图库Piker写法 会打开新的图库应用 选择完毕后会返回当前的应用
              // const photoViewPicker = new picker.PhotoViewPicker()

              // 调用选择 拉起图库
              photoViewPicker.select()
                .then((photoSelectResult) => {
                  AlertDialog.show({ message: JSON.stringify(photoSelectResult, null, 2) })
                })
            })

          Button('获取图库资源')
            .onClick(async () => {
              // 1. 获取图库管理器
              const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext());
              // 2.谓词 predicates是一个类型需要new 创建实例
              const predicates = new dataSharePredicates.DataSharePredicates()

              // predicates.orderByAsc() // 正序：从小到大
              predicates.orderByDesc(photoAccessHelper.PhotoKeys.DATE_ADDED) // 倒序：从大到小
              // 获取图库资源核心 api getAssets
              const fetchResult = await phAccessHelper.getAssets({
                fetchColumns: [photoAccessHelper.PhotoKeys.SIZE, photoAccessHelper.PhotoKeys.DATE_ADDED_MS], // 必传参数 查询列
                // 谓词 查找条件
                predicates: predicates
              })
              // 获取图片数量
              this.photoCount = fetchResult.getCount()
              // 获取第一张图片资源
              const photoAsset = await fetchResult.getFirstObject()
              this.photoAssetUri = photoAsset.uri
              this.photoAssetDisplayName = photoAsset.displayName
              const size = photoAsset.get(photoAccessHelper.PhotoKeys.SIZE) as number
              this.photoAssetSize = formatByteLength(size)
              // 获取图片添加日期（添加文件时间距1970年1月1日的毫秒数值）
              // 注意： arkts中时间戳毫秒值 秒数值需要×1000再dayjs格式化
              const dateAdd = photoAsset.get(photoAccessHelper.PhotoKeys.DATE_ADDED_MS) as number
              this.photoAssetDateAdded = dayjs(dateAdd * 1000)
                .format('YYYY-MM-DD HH:mm:ss')
              // AlertDialog.show({
              //   message:JSON.stringify({
              //     dateAdded:dateAdd,
              //     timeStamp:Date.now()
              //   },null,2)
              // })
            })
          Text('图片数量： ' + this.photoCount)
          Text('第一张图片名称： ' + this.photoAssetDisplayName)
          Text('第一张图片文件大小： ' + this.photoAssetSize)
          Text('第一张图片添加时间： ' + this.photoAssetDateAdded)
          Image(this.photoAssetUri)
            .width(200)

          Button('删除第一张图片')
            .onClick(async () => {
              // 1. 建立检索条件，用于获取图片资源。
              const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext())
              // 2. 调用PhotoAccessHelper.getAssets接口获取目标图片资源。
              const predicates = new dataSharePredicates.DataSharePredicates()
              const fetchResult = await phAccessHelper.getAssets({
                fetchColumns: [],
                predicates,
                // predicates:predicates
              })
              // 3. 调用FetchResult.getFirstObject接口获取第一张图片，即要放入回收站的图片对象。
              const photoAsset = await fetchResult.getFirstObject()
              // 4. 调用MediaAssetChangeRequest.deleteAssets接口将文件放入回收站。
              await photoAccessHelper.MediaAssetChangeRequest.deleteAssets(getContext(), [photoAsset]);
              Prompt.showToast({ message: '删除图片成功' })
            })

          Button('获取用户相册')
            .onClick(async () => {
              // 1. 建立检索条件，用于获取用户相册。
              const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext())
              const predicates = new dataSharePredicates.DataSharePredicates()
              const fetchOptions: photoAccessHelper.FetchOptions = {
                fetchColumns: [],
                predicates: predicates
              }
              const albumName = photoAccessHelper.AlbumKeys.ALBUM_NAME
              // 2. 调用PhotoAccessHelper.getAlbums接口获取用户相册资源。
              const fetchResult = await phAccessHelper.getAlbums(
                photoAccessHelper.AlbumType.USER, // 相册类型（用户相册 系统相册-我的收藏）
                photoAccessHelper.AlbumSubtype.USER_GENERIC, // 相册子类型（用户相册 收藏夹 视频相册）
                fetchOptions); // 可选参数
              // 3. 调用FetchResult.getFirstObject接口获取第一个用户相册。
              const album = await fetchResult.getFirstObject()
              this.albumCount = album.count.toString()
              this.albumCoverUri = album.coverUri
              this.albumName = album.albumName
            })
          Image(this.albumCoverUri).height(200)
          Text('用户相册名称： ' + this.albumName)
          Text('用户相册数量： ' + this.albumCount)
        }
        .constraintSize({ minHeight: '100%' })
      }
      .width('100%')
      .height('100%')
    }
    .title('Media Library Kit(媒体文件管理服务-图库)')
    .titleMode(NavigationTitleMode.Mini)
  }
}