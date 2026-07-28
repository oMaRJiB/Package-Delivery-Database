from faker import Faker
from random import sample, randint, choice, random, uniform
from datetime import datetime, timedelta

class dataGen:
    def __init__(self):
        self.faker = Faker()
        Faker.seed(42)

        self.file = open("PY_INSERT.sql",'w')

        #---- sizing vars ----
        self.customerCount = 128
        self.recipientCount = 100
        self.warehouseCount = 8
        self.truckCount = 25
        self.planeCount = 6
        self.accountCount = 48
        self.packageCount = 256
        self.crashTruckNo = 1721          #required by the "truck destroyed" query
        self.crashPackages = 6            #packages still on the truck at crash time
        self.crashPastPackages = 12       #earlier, already-delivered packages that truck handled

        #---- id counters shared across every locations subtype ----
        self.nextLocationId = 1
        self.nextAddressId = 1            #addresses.id piggybacks on locations.id (ISA)

        #---- bookkeeping used by later generators ----
        self.customerAddressIds = []      #addresses used by customers (parallel to customer id)
        self.recipientAddressIds = []     #addresses used by recipients
        self.warehouseLocationIds = []    #each warehouse's own location id
        self.truckLocationIds = []        #each truck's own location id
        self.truckNos = {}                #location_id -> truck_no
        self.planeLocationIds = []
        self.accountCustomerIds = {}      #customer_id -> account_id, for customers who are billed
        self.serviceIds = []
        self.serviceCosts = {}            #service_id -> (base, per_kg, hazard, intl, days)
        self.packageTypeCodes = []
        self.packages = []                #list of dicts, one per package
        self.nextPaymentId = 1
        self.nextEventId = 1

        self.file.write("-- Generated with fake_data.py\n")
        self.file.write("SET FOREIGN_KEY_CHECKS=0;\n")

        self.addressGen(self.customerCount, self.customerAddressIds, "Customer")
        self.customerGen(self.customerCount)

        self.addressGen(self.recipientCount, self.recipientAddressIds, "Recipient")
        self.recipientGen(self.recipientCount)

        self.accountGen(self.accountCount)

        self.packageTypeSetup()
        self.serviceSetup()

        self.warehouseGen(self.warehouseCount)
        self.truckGen(self.truckCount)
        self.planeGen(self.planeCount)

        self.packageAndPaymentGen(self.packageCount)
        self.customsGen()
        self.trackingGen()
        self.invoiceGen()

        self.file.write("\nSET FOREIGN_KEY_CHECKS=1;\n")

        self.file.close()

    #locations / addresses  (every address is ALSO a location, per the FK)
    def addressGen(self, count: int, idList: list, category: str):
        self.file.write(f"-- {category} Addresses\n")
        for _ in range(count):
            locId = self.nextLocationId
            self.nextLocationId += 1
            street = self.faker.street_address().replace("'", "''")
            city = self.faker.city().replace("'", "''")
            state = self.faker.state_abbr()
            _zip = self.faker.zipcode()[:9]
            self.file.write(f"INSERT INTO locations(id) VALUES({locId});\n")
            self.file.write(f"INSERT INTO addresses(id, street, city, state_province, postal_code, country) "
                            f"VALUES({locId}, '{street}', '{city}', '{state}', '{_zip}', 'US');\n")
            idList.append(locId)
        self.file.write("\n")

    def customerGen(self, count: int):
        self.file.write("-- Customers\n")
        addressOrder = sample(self.customerAddressIds, count)
        for i in range(1, count + 1):
            name = self.faker.name()
            email = (name[0] + name.split()[-1] + str(i) + '@example.com').lower()
            phone = self.faker.basic_phone_number().replace('-', '').replace('(', '').replace(')', '')[:10]
            address = addressOrder[i - 1]
            self.file.write(f"INSERT INTO customers(id, name, email, phone, address_id) "
                            f"VALUES({i}, '{name}', '{email}', '{phone}', '{address}');\n")
        self.file.write("\n")

    def recipientGen(self, count: int):
        self.file.write("-- Recipients\n")
        addressOrder = sample(self.recipientAddressIds, count)
        for i in range(1, count + 1):
            name = self.faker.name()
            phone = self.faker.basic_phone_number().replace('-', '').replace('(', '').replace(')', '')[:10]
            address = addressOrder[i - 1]
            self.file.write(f"INSERT INTO recipients(id, name, phone, address_id) "
                            f"VALUES({i}, '{name}', '{phone}', '{address}');\n")
        self.file.write("\n")

    def accountGen(self, count: int):
        self.file.write('-- Accounts\n')
        customersWithAccounts = sample(range(1, self.customerCount + 1), count)
        for i in range(1, count + 1):
            custId = customersWithAccounts[i - 1]
            self.accountCustomerIds[custId] = i
            self.file.write(f"INSERT INTO accounts(id, customer_id) VALUES({i},{custId});\n")
        self.file.write("\n")

    #reference / lookup tables
    def packageTypeSetup(self):
        #Already inserted separately -- codes match the existing package_types rows.
        self.packageTypeCodes = ["letter", "sbox", "mbox", "lbox", "xlbox"]

    def serviceSetup(self):
        #Already inserted separately (auto-increment ids, in this insertion order):
        #1 First-Class Mail, 2 Ground Advantage, 3 Priority Mail,
        #4 Priority Mail Express, 5 Media Mail.
        #base_cost, per_kg_cost, hazard_surcharge, intl_surcharge, delivery_time_estimate(days)
        services = {
            1: (1.00, 0.00, 10.00, 15.00, 5),
            2: (7.90, 1.50, 10.00, 20.00, 5),
            3: (11.00, 2.50, 12.50, 25.00, 3),
            4: (35.65, 5.00, 15.00, 30.00, 2),
            5: (4.39, 1.00, 10.00, 20.00, 8),
        }
        self.serviceIds = list(services.keys())
        self.serviceCosts = services

    #facilities: each gets its own location id (separate from any address)
    def warehouseGen(self, count: int):
        self.file.write("-- Warehouses\n")
        #warehouses also need an address; generate one address per warehouse first
        whAddressIds = []
        self.addressGen(count, whAddressIds, "Warehouse")
        for i in range(count):
            locId = self.nextLocationId
            self.nextLocationId += 1
            addrId = whAddressIds[i]
            self.file.write(f"INSERT INTO locations(id) VALUES({locId});\n")
            self.file.write(f"INSERT INTO warehouses(location_id, address_id) VALUES({locId}, {addrId});\n")
            self.warehouseLocationIds.append(locId)
        self.file.write("\n")

    def truckGen(self, count: int):
        self.file.write("-- Trucks\n")
        truckNos = sample(range(1000, 9999), count - 1)
        truckNos.append(self.crashTruckNo)  #guarantee truck 1721 exists
        for truckNo in truckNos:
            locId = self.nextLocationId
            self.nextLocationId += 1
            self.file.write(f"INSERT INTO locations(id) VALUES({locId});\n")
            self.file.write(f"INSERT INTO trucks(location_id, truck_no) VALUES({locId}, {truckNo});\n")
            self.truckLocationIds.append(locId)
            self.truckNos[locId] = truckNo
        self.file.write("\n")

    def planeGen(self, count: int):
        self.file.write("-- Planes\n")
        for _ in range(count):
            locId = self.nextLocationId
            self.nextLocationId += 1
            tail = "N" + str(randint(100, 999)) + choice("ABCDEFGH")
            self.file.write(f"INSERT INTO locations(id) VALUES({locId});\n")
            self.file.write(f"INSERT INTO planes(location_id, tail_no) VALUES({locId}, '{tail}');\n")
            self.planeLocationIds.append(locId)
        self.file.write("\n")

    #payments (+ prepaid labels) and packages, generated together since
    #every package requires a payment_id to already exist
    def _newPayment(self, amount: float, when: datetime) -> int:
        pid = self.nextPaymentId
        self.nextPaymentId += 1
        self.file.write(f"INSERT INTO payments(id, amount, payment_time) "
                        f"VALUES({pid}, {amount:.2f}, '{when.strftime('%Y-%m-%d %H:%M:%S')}');\n")
        return pid

    def packageAndPaymentGen(self, count: int):
        self.file.write("-- Payments, prepaid labels, and packages\n")
        now = datetime(2026, 7, 27, 9, 0, 0)
        earliest = now - timedelta(days=365)

        trackingSeq = 1
        for _ in range(count):
            customerId = randint(1, self.customerCount)
            recipientId = randint(1, self.recipientCount)
            typeCode = choice(self.packageTypeCodes)
            serviceId = choice(self.serviceIds)
            weight = round(uniform(0.2, 25.0), 2)
            isHazard = 1 if(random() < 0.06) else 0
            isIntl = 1 if(random() < 0.15) else 0

            base, perkg, hzCost, intlCost, days = self.serviceCosts[serviceId]
            amount = base + perkg * weight
            if(isHazard):
                amount += hzCost
            if(isIntl):
                amount += intlCost

            shippedAt = earliest + timedelta(seconds=randint(0, int((now - earliest).total_seconds())))
            expectedDelivery = shippedAt + timedelta(days=days)

            isAccountBilled = customerId in self.accountCustomerIds
            isPrepaid = (not isAccountBilled) and random() < 0.10

            if(isPrepaid):
                #label bought a few days before drop-off
                purchaseTime = shippedAt - timedelta(days=randint(1, 10))
                paymentId = self._newPayment(amount, purchaseTime)
                labelCode = self.faker.bothify(text="LBL-########").upper()
                self.file.write(f"INSERT INTO prepaid_labels(label_code, payment_id) VALUES('{labelCode}', {paymentId});\n")
            elif(isAccountBilled):
                #settled later, near when the monthly invoice would be paid
                payTime = shippedAt + timedelta(days=randint(15, 40))
                if(payTime > now):
                    payTime = now
                paymentId = self._newPayment(amount, payTime)
            else:
                #paid by card at drop-off
                payTime = shippedAt + timedelta(minutes=randint(0, 30))
                paymentId = self._newPayment(amount, payTime)

            trackingNo = f"TRK{trackingSeq:07d}"
            trackingSeq += 1

            self.file.write(f"INSERT INTO packages(tracking_no, customer_id, recipient_id, type_code, weight, "
                            f"service_code, is_hazard, is_intl, payment_id, shipped_at, expected_delivery_date) "
                            f"VALUES('{trackingNo}', {customerId}, {recipientId}, '{typeCode}', {weight}, {serviceId}, {isHazard}, {isIntl}, {paymentId}, '{shippedAt.strftime('%Y-%m-%d %H:%M:%S')}', '{expectedDelivery.strftime('%Y-%m-%d %H:%M:%S')}');\n")

            self.packages.append({
                "tracking_no": trackingNo,
                "customer_id": customerId,
                "recipient_id": recipientId,
                "account_id": self.accountCustomerIds.get(customerId),
                "payment_id": paymentId,
                "amount": amount,
                "shipped_at": shippedAt,
                "expected_delivery": expectedDelivery,
                "is_intl": isIntl,
                "is_hazard": isHazard,
                "weight": weight,
            })
        self.file.write("\n")

    #customs declarations, only for international packages
    def customsGen(self):
        self.file.write("-- Customs declarations\n")
        countries = ["CA", "MX", "GB", "DE", "FR", "JP", "AU", "BR", "IN", "CN"]
        declId = 1
        itemId = 1
        for pkg in self.packages:
            if(not pkg["is_intl"]):
                continue
            dest = choice(countries)
            itemCount = randint(1, 4)
            totalValue = 0.0
            lines = []
            for lineNo in range(1, itemCount + 1):
                value = round(uniform(10.0, 400.0), 2)
                qty = randint(1, 3)
                totalValue += value * qty
                desc = self.faker.word().capitalize() + " " + self.faker.word()
                lines.append((lineNo, value, desc.replace("'", "''"), qty))

            self.file.write(
                f"INSERT INTO customs_declarations(id, tracking_no, origin_country, destination_country, total_value) "
                f"VALUES({declId}, '{pkg['tracking_no']}', 'US', '{dest}', {totalValue:.2f});\n"
            )
            for lineNo, value, desc, qty in lines:
                self.file.write(
                    f"INSERT INTO customs_items(id, declaration_id, line_no, item_value, description, quantity) "
                    f"VALUES({itemId}, {declId}, '{lineNo}', {value}, '{desc}', {qty});\n"
                )
                itemId += 1
            declId += 1
        self.file.write("\n")

    #tracking events + deliveries
    def _customerLocationId(self, customerId: int) -> int:
        return self.customerAddressIds[customerId - 1]

    def _recipientLocationId(self, recipientId: int) -> int:
        return self.recipientAddressIds[recipientId - 1]

    def _createTrackEvent(self, trackingNo: str, when: datetime, locationId: int, eventType: str) -> int:
        eid = self.nextEventId
        self.nextEventId += 1
        self.file.write(
            f"INSERT INTO tracking_events(id, tracking_no, event_time, location_id, event_type) "
            f"VALUES({eid}, '{trackingNo}', '{when.strftime('%Y-%m-%d %H:%M:%S')}', {locationId}, '{eventType}');\n"
        )
        return eid

    def trackingGen(self):
        self.file.write("-- Tracking events & deliveries")
        crashTime = datetime(2026, 7, 20, 14, 0, 0)
        crashTruckLoc = next(loc for loc, no in self.truckNos.items() if(no == self.crashTruckNo))

        #pick which packages ride the doomed truck, both before and during the crash
        candidateIdx = [i for i, p in enumerate(self.packages) if(p["shipped_at"] < crashTime)]
        sample(candidateIdx, 0)  #no-op, keeps randint usage consistent
        pastIdx = sample(candidateIdx, min(self.crashPastPackages, len(candidateIdx)))
        remaining = [i for i in candidateIdx if(i not in pastIdx)]
        stuckIdx = sample(remaining, min(self.crashPackages, len(remaining)))

        for i, pkg in enumerate(self.packages):
            originWh = choice(self.warehouseLocationIds)
            destWh = choice(self.warehouseLocationIds)
            t = pkg["shipped_at"]

            self._createTrackEvent(pkg["tracking_no"], t, self._customerLocationId(pkg["customer_id"]), "PICKUP")
            t += timedelta(hours=uniform(1, 6))
            self._createTrackEvent(pkg["tracking_no"], t, originWh, "ARRIVE")

            if(i in stuckIdx):
                #still sitting on truck 1721 when it was destroyed -- no further events
                loadTime = crashTime - timedelta(hours=uniform(1, 20))
                self._createTrackEvent(pkg["tracking_no"], loadTime, crashTruckLoc, "LOAD")
                continue

            truckOrPlane = choice(self.truckLocationIds + self.planeLocationIds)
            if(i in pastIdx):
                truckOrPlane = crashTruckLoc

            t += timedelta(hours=uniform(0.5, 3))
            self._createTrackEvent(pkg["tracking_no"], t, truckOrPlane, "LOAD")
            t += timedelta(minutes=uniform(10, 60))
            self._createTrackEvent(pkg["tracking_no"], t, originWh, "DEPART")
            t += timedelta(hours=uniform(4, 48))
            self._createTrackEvent(pkg["tracking_no"], t, destWh, "ARRIVE")

            if(random() < 0.03):
                t += timedelta(hours=uniform(1, 12))
                self._createTrackEvent(pkg["tracking_no"], t, destWh, "EXCEPTION")

            #some packages are simply late or never marked delivered
            if(random() < 0.08):
                continue

            t += timedelta(hours=uniform(2, 10))
            self._createTrackEvent(pkg["tracking_no"], t, destWh, "OUT_FOR_DELIVERY")
            t += timedelta(hours=uniform(1, 8))
            if(random() < 0.12):
                #deliver later than promised
                t = pkg["expected_delivery"] + timedelta(hours=uniform(1, 48))
            deliverLoc = self._recipientLocationId(pkg["recipient_id"])
            eid = self._createTrackEvent(pkg["tracking_no"], t, deliverLoc, "DELIVERED")

            signer = self.faker.name().replace("'", "''")
            self.file.write(
                f"INSERT INTO deliveries(event_id, delivery_time, signed_by) "
                f"VALUES({eid}, '{t.strftime('%Y-%m-%d %H:%M:%S')}', '{signer}');\n"
            )
        self.file.write("\n")

    #monthly invoices for account customers + the payments that settle them
    def invoiceGen(self):
        self.file.write("-- Invoices & account charges\n")
        byAccountMonth = {}
        for pkg in self.packages:
            if(pkg["account_id"] is None):
                continue
            key = (pkg["account_id"], pkg["shipped_at"].year, pkg["shipped_at"].month)
            byAccountMonth.setdefault(key, []).append(pkg)

        invoiceId = 1
        chargeId = 1
        for (accountId, year, month), pkgs in sorted(byAccountMonth.items()):
            if(month == 12):
                invoiceDate = datetime(year + 1, 1, 1)
            else:
                invoiceDate = datetime(year, month + 1, 1)
            dueDate = invoiceDate + timedelta(days=15)

            self.file.write(
                f"INSERT INTO invoices(id, account_id, invoice_date, due_date) "
                f"VALUES({invoiceId}, {accountId}, '{invoiceDate.strftime('%Y-%m-%d %H:%M:%S')}', "
                f"'{dueDate.strftime('%Y-%m-%d %H:%M:%S')}');\n"
            )
            for pkg in pkgs:
                self.file.write(
                    f"INSERT INTO account_charges(id, payment_id, invoice_id) "
                    f"VALUES({chargeId}, {pkg['payment_id']}, {invoiceId});\n"
                )
                chargeId += 1
            invoiceId += 1
        self.file.write("\n")


if(__name__ == '__main__'):
    dataGen()
    print("Generation Successful!")