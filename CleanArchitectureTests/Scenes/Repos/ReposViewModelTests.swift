//
// ReposViewModelTests.swift
// CleanArchitecture
//
// Created by Tuan Truong on 6/28/18.
// Copyright © 2018 Framgia. All rights reserved.
//

@testable import CleanArchitecture
import XCTest
import RxSwift
import RxBlocking

final class ReposViewModelTests: XCTestCase {
    private var viewModel: ReposViewModel!
    private var navigator: ReposNavigatorMock!
    private var useCase: ReposUseCaseMock!
    
    private var input: ReposViewModel.Input!
    private var output: ReposViewModel.Output!
    
    private var disposeBag: DisposeBag!
    
    private let loadTrigger = PublishSubject<Void>()
    private let reloadTrigger = PublishSubject<Void>()
    private let loadMoreTrigger = PublishSubject<Void>()
    private let selectRepoTrigger = PublishSubject<IndexPath>()

    override func setUp() {
        super.setUp()
        navigator = ReposNavigatorMock()
        useCase = ReposUseCaseMock()
        viewModel = ReposViewModel(navigator: navigator, useCase: useCase)
        
        input = ReposViewModel.Input(
            loadTrigger: loadTrigger.asDriverOnErrorJustComplete(),
            reloadTrigger: reloadTrigger.asDriverOnErrorJustComplete(),
            loadMoreTrigger: loadMoreTrigger.asDriverOnErrorJustComplete(),
            selectRepoTrigger: selectRepoTrigger.asDriverOnErrorJustComplete()
        )
        
        output = viewModel.transform(input)
        
        disposeBag = DisposeBag()
        
        output.error.drive().disposed(by: disposeBag)
        output.loading.drive().disposed(by: disposeBag)
        output.refreshing.drive().disposed(by: disposeBag)
        output.loadingMore.drive().disposed(by: disposeBag)
        output.fetchItems.drive().disposed(by: disposeBag)
        output.repoList.drive().disposed(by: disposeBag)
        output.selectedRepo.drive().disposed(by: disposeBag)
        output.isEmptyData.drive().disposed(by: disposeBag)
    }

    func test_loadTriggerInvoked_getRepoList() {
        // act
        loadTrigger.onNext(())
        let repoList = try? output.repoList.toBlocking(timeout: 1).first()
        
        // assert
        XCTAssert(useCase.getRepoListCalled)
        XCTAssertEqual(repoList??.count, 1)
    }

    func test_loadTriggerInvoked_getRepoList_failedShowError() {
        // arrange
        let getRepoListReturnValue = PublishSubject<PagingInfo<Repo>>()
        useCase.getRepoListReturnValue = getRepoListReturnValue

        // act
        loadTrigger.onNext(())
        getRepoListReturnValue.onError(TestError())
        let error = try? output.error.toBlocking(timeout: 1).first()

        // assert
        XCTAssert(useCase.getRepoListCalled)
        XCTAssert(error is TestError)
    }

    func test_reloadTriggerInvoked_getRepoList() {
        // act
        reloadTrigger.onNext(())
        let repoList = try? output.repoList.toBlocking(timeout: 1).first()

        // assert
        XCTAssert(useCase.getRepoListCalled)
        XCTAssertEqual(repoList??.count, 1)
    }

    func test_reloadTriggerInvoked_getRepoList_failedShowError() {
        // arrange
        let getRepoListReturnValue = PublishSubject<PagingInfo<Repo>>()
        useCase.getRepoListReturnValue = getRepoListReturnValue

        // act
        reloadTrigger.onNext(())
        getRepoListReturnValue.onError(TestError())
        let error = try? output.error.toBlocking(timeout: 1).first()

        // assert
        XCTAssert(useCase.getRepoListCalled)
        XCTAssert(error is TestError)
    }

    func test_reloadTriggerInvoked_notGetRepoListIfStillLoading() {
        // arrange
        let getRepoListReturnValue = PublishSubject<PagingInfo<Repo>>()
        useCase.getRepoListReturnValue = getRepoListReturnValue

        // act
        loadTrigger.onNext(())
        useCase.getRepoListCalled = false
        reloadTrigger.onNext(())

        // assert
        XCTAssertFalse(useCase.getRepoListCalled)
    }

    func test_reloadTriggerInvoked_notGetRepoListIfStillReloading() {
        // arrange
        let getRepoListReturnValue = PublishSubject<PagingInfo<Repo>>()
        useCase.getRepoListReturnValue = getRepoListReturnValue

        // act
        reloadTrigger.onNext(())
        useCase.getRepoListCalled = false
        reloadTrigger.onNext(())

        // assert
        XCTAssertFalse(useCase.getRepoListCalled)
    }

    func test_loadMoreTriggerInvoked_loadMoreRepoList() {
        // act
        loadTrigger.onNext(())
        loadMoreTrigger.onNext(())
        let repoList = try? output.repoList.toBlocking(timeout: 1).first()

        // assert
        XCTAssert(useCase.loadMoreRepoListCalled)
        XCTAssertEqual(repoList??.count, 2)
    }

    func test_loadMoreTriggerInvoked_loadMoreRepoList_failedShowError() {
        // arrange
        let loadMoreRepoListReturnValue = PublishSubject<PagingInfo<Repo>>()
        useCase.loadMoreRepoListReturnValue = loadMoreRepoListReturnValue

        // act
        loadTrigger.onNext(())
        loadMoreTrigger.onNext(())
        loadMoreRepoListReturnValue.onError(TestError())
        let error = try? output.error.toBlocking(timeout: 1).first()

        // assert
        XCTAssert(useCase.loadMoreRepoListCalled)
        XCTAssert(error is TestError)
    }

    func test_loadMoreTriggerInvoked_notLoadMoreRepoListIfStillLoading() {
        // arrange
        let getRepoListReturnValue = PublishSubject<PagingInfo<Repo>>()
        useCase.getRepoListReturnValue = getRepoListReturnValue

        // act
        loadTrigger.onNext(())
        useCase.getRepoListCalled = false
        loadMoreTrigger.onNext(())

        // assert
        XCTAssertFalse(useCase.loadMoreRepoListCalled)
    }

    func test_loadMoreTriggerInvoked_notLoadMoreRepoListIfStillReloading() {
        // arrange
        let getRepoListReturnValue = PublishSubject<PagingInfo<Repo>>()
        useCase.getRepoListReturnValue = getRepoListReturnValue

        // act
        reloadTrigger.onNext(())
        useCase.getRepoListCalled = false
        loadMoreTrigger.onNext(())
        
        // assert
        XCTAssertFalse(useCase.loadMoreRepoListCalled)
    }

    func test_loadMoreTriggerInvoked_notLoadMoreDocumentTypesStillLoadingMore() {
        // arrange
        let loadMoreRepoListReturnValue = PublishSubject<PagingInfo<Repo>>()
        useCase.loadMoreRepoListReturnValue = loadMoreRepoListReturnValue
        
        // act
        loadMoreTrigger.onNext(())
        useCase.loadMoreRepoListCalled = false
        loadMoreTrigger.onNext(())

        // assert
        XCTAssertFalse(useCase.loadMoreRepoListCalled)
    }

    func test_selectRepoTriggerInvoked_toRepoDetail() {
        // act
        loadTrigger.onNext(())
        selectRepoTrigger.onNext(IndexPath(row: 0, section: 0))

        // assert
        XCTAssert(navigator.toRepoDetailCalled)
    }
}

