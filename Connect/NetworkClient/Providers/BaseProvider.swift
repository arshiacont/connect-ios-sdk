/*
 *  Copyright (c) 2018 Zendesk. All rights reserved.
 *
 *  By downloading or using the Zendesk Mobile SDK, You agree to the Zendesk Master
 *  Subscription Agreement https://www.zendesk.com/company/customers-partners/master-subscription-agreement and Application Developer and API License
 *  Agreement https://www.zendesk.com/company/customers-partners/application-developer-api-license-agreement and
 *  acknowledge that such terms govern Your use of and access to the Mobile SDK.
 *
 */

import Foundation

class BaseProvider {
    
    var client: Client
    
    /// init of the Provider class, ensures a client is passed correctly to sub classes
    ///
    /// - Parameter client: Client instance
    init(with client: Client) {
        self.client = client
    }
    
}
