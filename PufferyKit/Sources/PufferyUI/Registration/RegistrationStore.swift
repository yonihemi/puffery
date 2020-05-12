//
//  RegistrationViewModel.swift
//
//
//  Created by Valentin Knabel on 10.05.20.
//

import ComposableArchitecture
import Foundation
import PufferyKit

struct RegistrationState: Equatable {
    var email = ""
    var activity = ActivityState.idle

    var shouldCheckEmails = false

    enum ActivityState: Equatable {
        case idle
        case inProgress
        case failed(FetchingError)

        var inProgress: Bool {
            if case .inProgress = self {
                return true
            } else {
                return false
            }
        }
    }
}

enum RegistrationAction {
    case updateEmail(String)
    // TODO: remove onFinish
    case shouldRegister(onFinish: () -> Void)
    case shouldLogin(onFinish: () -> Void)

    case showCheckEmails(Bool)

    case activityFinished
    case activityFailed(FetchingError)
}

let registrationReducer = Reducer<
    RegistrationState,
    RegistrationAction,
    RegistrationEnvironment
> { (state, action, environment: RegistrationEnvironment) in
    switch action {
    case let .updateEmail(email):
        state.email = email
        return .none
    case let .showCheckEmails(shows):
        state.shouldCheckEmails = shows
        return .none
    case .shouldRegister where state.email.isEmpty || state.activity.inProgress:
        return .none

    case .activityFinished:
        state.activity = .idle
        return .none
    case let .activityFailed(error):
        state.activity = .failed(error)
        return .none

    case let .shouldLogin(onFinish: onFinish):
        state.activity = .inProgress

        return environment.loginEffect(state.email)
            .handleEvents(receiveOutput: { onFinish() })
            .transform(to: RegistrationAction.activityFinished)
            .prepend(RegistrationAction.showCheckEmails(true))
            .catch { fetchingError in
                Effect<RegistrationAction, Never>(value: RegistrationAction.activityFailed(fetchingError))
            }
            .eraseToEffect()

    case let .shouldRegister(onFinish: onFinish):
        state.activity = .inProgress

        return environment.registerEffect(state.email)
            .handleEvents(receiveOutput: { _ in onFinish() })
            .transform(to: RegistrationAction.activityFinished)
            .catch { fetchingError in
                Effect<RegistrationAction, Never>(value: RegistrationAction.activityFailed(fetchingError))
            }
            .eraseToEffect()
    }
}