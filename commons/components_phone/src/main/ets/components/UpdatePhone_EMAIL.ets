import { UserLoginInfo } from "common";

@Component
export struct UpdatePhone_EMAIL {
  @State userLoginInfo: UserLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo

  build() {
    
  }
}