import XCTest
@testable import XcodeProj

final class PBXProjectTests: XCTestCase {
    func test_attributes() throws {
        let target = PBXTarget(name: "")
        target.reference.fix("app")

        let testTarget = PBXTarget(name: "")
        testTarget.reference.fix("test")

        let project = PBXProject(name: "",
                                 buildConfigurationList: XCConfigurationList(),
                                 compatibilityVersion: "",
                                 mainGroup: PBXGroup(),
                                 attributes: ["LastUpgradeCheck": "0940"],
                                 targetAttributes: [target: ["TestTargetID": "123"]])

        project.setTargetAttributes(["custom": "abc", "TestTargetID": testTarget], target: target)

        let plist = try project.plistKeyAndValue(proj: PBXProj(), reference: "")
        let attributes = plist.value.dictionary?["attributes"]?.dictionary ?? [:]

        let expectedAttributes: [CommentedString: PlistValue] = [
            "LastUpgradeCheck": "0940",
            "TargetAttributes": ["app": [
                "custom": "abc",
                "TestTargetID": "test",
            ]],
        ]
        XCTAssertEqual(attributes, expectedAttributes)
    }
    
    func test_addLocalSwiftPackage() throws {
        // Given
        let objects = PBXObjects(objects: [])

        let buildPhase = PBXFrameworksBuildPhase(
            files: [],
            inputFileListPaths: nil,
            outputFileListPaths: nil, buildActionMask: PBXBuildPhase.defaultBuildActionMask,
            runOnlyForDeploymentPostprocessing: true
        )
        let target = PBXNativeTarget(name: "Target",
                                     buildConfigurationList: nil,
                                     buildPhases: [buildPhase])
        objects.add(object: target)
        
        let configurationList = XCConfigurationList.fixture()
        let mainGroup = PBXGroup.fixture()
        objects.add(object: configurationList)
        objects.add(object: mainGroup)

        let project = PBXProject(name: "Project",
                                 buildConfigurationList: configurationList,
                                 compatibilityVersion: "0",
                                 mainGroup: mainGroup,
                                 targets: [target])

        objects.add(object: project)
        
        // When
        let packageProduct = try project.addLocalSwiftPackage(path: "Product",
                                         productName: "Product",
                                         targetName: "Target")
        
        // Then
        XCTAssertEqual(packageProduct, objects.buildFiles.first?.value.product)
        XCTAssertEqual(packageProduct, objects.swiftPackageProductDependencies.first?.value)
        
        XCTAssertEqual(objects.fileReferences.first?.value.name, "Product")
        
        XCTAssertEqual(objects.swiftPackageProductDependencies.first?.value, buildPhase.files?.first?.product)
    }
    
    func test_addSwiftPackage() throws {
        // Given
        let objects = PBXObjects(objects: [])
        
        let buildPhase = PBXSourcesBuildPhase(
            files: [],
            inputFileListPaths: nil,
            outputFileListPaths: nil, buildActionMask: PBXBuildPhase.defaultBuildActionMask,
            runOnlyForDeploymentPostprocessing: true
        )
        let target = PBXNativeTarget(name: "Target",
                                     buildConfigurationList: nil,
                                     buildPhases: [buildPhase])
        objects.add(object: target)
        
        let configurationList = XCConfigurationList.fixture()
        let mainGroup = PBXGroup.fixture()
        objects.add(object: configurationList)
        objects.add(object: mainGroup)
        
        let project = PBXProject(name: "Project",
                                 buildConfigurationList: configurationList,
                                 compatibilityVersion: "0",
                                 mainGroup: mainGroup,
                                 targets: [target])
        
        objects.add(object: project)
        
        // When
        let remoteReference = try project.addSwiftPackage(repositoryURL: "url",
                                                         productName: "Product",
                                                         versionRequirement: .branch("master"),
                                                         target: target)
        
        // Then
        XCTAssertEqual(remoteReference, project.packages.first)
        XCTAssertEqual(remoteReference, objects.remoteSwiftPackageReferences.first?.value)
        
        XCTAssertEqual(remoteReference, objects.buildFiles.first?.value.product?.package)
        XCTAssertEqual(objects.swiftPackageProductDependencies.first?.value, buildPhase.files?.first?.product)
    }
}
