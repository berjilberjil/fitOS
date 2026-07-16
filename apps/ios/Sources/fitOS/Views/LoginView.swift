import SwiftUI

struct LoginView: View {
    @EnvironmentObject var state: AppState
    @State private var username = ""
    @State private var password = ""
    @State private var isRegister = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 6) {
                Text("fitOS")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.text)
                Text(isRegister ? "Create your account" : "Welcome back")
                    .font(.system(size: 15)).foregroundStyle(Palette.muted)
            }
            .padding(.bottom, 36)

            VStack(spacing: 12) {
                field("Username", text: $username)
                secureField("Password", text: $password)

                if let err = state.authError {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryButton(title: isRegister ? "Create account" : "Log in",
                              loading: state.isWorking) {
                    Task { await submit() }
                }
                .padding(.top, 4)

                Button {
                    isRegister.toggle()
                    state.authError = nil
                } label: {
                    Text(isRegister ? "Have an account? Log in"
                                    : "New here? Create an account")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.muted)
                }
                .padding(.top, 6)
            }
            .padding(20)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(Palette.border, lineWidth: 1)
            )
            .padding(.horizontal, 20)

            Spacer(); Spacer()
        }
        .background(Palette.bg.ignoresSafeArea())
    }

    private func submit() async {
        let u = username.trimmingCharacters(in: .whitespaces).lowercased()
        if isRegister {
            await state.register(username: u, password: password)
        } else {
            await state.login(username: u, password: password)
        }
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundColor(Palette.faint))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(14)
            .background(Palette.surface2)
            .foregroundStyle(Palette.text)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    private func secureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField("", text: text, prompt: Text(placeholder).foregroundColor(Palette.faint))
            .padding(14)
            .background(Palette.surface2)
            .foregroundStyle(Palette.text)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}
