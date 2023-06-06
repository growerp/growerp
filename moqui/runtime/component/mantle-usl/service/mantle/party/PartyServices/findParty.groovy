/*
 * This software is in the public domain under CC0 1.0 Universal plus a 
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import org.moqui.context.ExecutionContext
import org.moqui.entity.EntityCondition
import org.moqui.entity.EntityFind
import org.moqui.entity.EntityList
import org.moqui.entity.EntityValue

// org.slf4j.Logger logger = org.slf4j.LoggerFactory.getLogger("findParty")

ExecutionContext ec = context.ec

// NOTE: doing a find with a static view-entity because the Entity Facade will only select the fields specified and the
//     join in the associated member-entities
EntityFind ef = ec.entity.find("mantle.party.FindPartyView").distinct(true)
// don't do distinct, SQL quandary with distinct, limited select, and order by with upper needing to be selected; seems to get good results in general without: .distinct(true)

ef.selectField("partyId")

if (partyId) { ef.condition(ec.entity.conditionFactory.makeCondition("partyId", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + partyId + "%").ignoreCase()) }
if (pseudoId) { ef.condition(ec.entity.conditionFactory.makeCondition("pseudoId", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + pseudoId + "%").ignoreCase()) }
if (partyTypeEnumId) { ef.condition("partyTypeEnumId", partyTypeEnumId) }
if (disabled) { ef.condition("disabled", disabled) }
if (customerStatusId) { ef.condition("customerStatusId", customerStatusId) }
if (hasDuplicates) { ef.condition("hasDuplicates", hasDuplicates) }
if (roleTypeId) { ef.condition("roleTypeId", roleTypeId) }
if (username) { ef.condition(ec.entity.conditionFactory.makeCondition("username", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + username + "%").ignoreCase()) }

if (combinedName) {
    // support splitting by just one space for first/last names
    String fnSplit = combinedName
    String lnSplit = combinedName
    if (combinedName.contains(" ")) {
        fnSplit = combinedName.substring(0, combinedName.indexOf(" "))
        lnSplit = combinedName.substring(combinedName.indexOf(" ") + 1)
    }
    cnCondList = [ec.entity.conditionFactory.makeCondition("organizationName", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + combinedName + "%").ignoreCase(),
            ec.entity.conditionFactory.makeCondition("firstName", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + fnSplit + "%").ignoreCase(),
            ec.entity.conditionFactory.makeCondition("lastName", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + lnSplit + "%").ignoreCase()]
    ef.condition(ec.entity.conditionFactory.makeCondition(cnCondList, EntityCondition.OR))
}

if (organizationName) { ef.condition(ec.entity.conditionFactory.makeCondition("organizationName", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + organizationName + "%").ignoreCase()) }
if (firstName) { ef.condition(ec.entity.conditionFactory.makeCondition("firstName", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + firstName + "%").ignoreCase()) }
if (lastName) { ef.condition(ec.entity.conditionFactory.makeCondition("lastName", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + lastName + "%").ignoreCase()) }
if (suffix) { ef.condition(ec.entity.conditionFactory.makeCondition("suffix", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + suffix + "%").ignoreCase()) }

if (address1) { ef.condition(ec.entity.conditionFactory.makeCondition("address1", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + address1 + "%").ignoreCase()) }
if (address2) { ef.condition(ec.entity.conditionFactory.makeCondition("address2", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + address2 + "%").ignoreCase()) }
if (city) { ef.condition(ec.entity.conditionFactory.makeCondition("city", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + city + "%").ignoreCase()) }
if (stateProvinceGeoId) { ef.condition("stateProvinceGeoId", stateProvinceGeoId) }
if (postalCode) { ef.condition(ec.entity.conditionFactory.makeCondition("postalCode", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + postalCode + "%").ignoreCase()) }

if (countryCode) { ef.condition("countryCode", countryCode) }
if (areaCode) { ef.condition("areaCode", areaCode) }
if (contactNumber) { ef.condition(ec.entity.conditionFactory.makeCondition("contactNumber", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + contactNumber + "%")) }

if (emailAddress) { ef.condition(ec.entity.conditionFactory.makeCondition("emailAddress", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + emailAddress + "%").ignoreCase()) }

if (assetSerialNumber) { ef.condition(ec.entity.conditionFactory.makeCondition("assetSerialNumber", EntityCondition.LIKE, (leadingWildcard ? "%" : "") + assetSerialNumber + "%").ignoreCase()) }

if (orderByField) {
    if (orderByField.contains("combinedName")) {
        if (orderByField.contains("-")) ef.orderBy("-organizationName,-firstName,-lastName")
        else ef.orderBy("organizationName,firstName,lastName")
    } else {
        ef.orderBy(orderByField)
    }
}

if (!pageNoLimit) { ef.offset(pageIndex as int, pageSize as int); ef.limit(pageSize as int) }

// logger.warn("======= find#Party cond: ${ef.getWhereEntityCondition()}")

partyIdList = []
EntityList el = ef.list()
for (EntityValue ev in el) partyIdList.add(ev.partyId)

partyIdListCount = ef.count()
partyIdListPageIndex = ef.pageIndex
partyIdListPageSize = ef.pageSize
partyIdListPageMaxIndex = ((BigDecimal) (partyIdListCount - 1)).divide(partyIdListPageSize, 0, BigDecimal.ROUND_DOWN) as int
partyIdListPageRangeLow = partyIdListPageIndex * partyIdListPageSize + 1
partyIdListPageRangeHigh = (partyIdListPageIndex * partyIdListPageSize) + partyIdListPageSize
if (partyIdListPageRangeHigh > partyIdListCount) partyIdListPageRangeHigh = partyIdListCount
