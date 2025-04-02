import '../models/insurance_model.dart';
import '../models/retirement_model.dart';

class HomeViewModel {
  List<InsuranceProduct> getInsuranceProducts() {
    return [
      InsuranceProduct(
        id: '1',
        name: 'Hayat Sigortası',
        description: 'Geleceğinizi ve sevdiklerinizi güvence altına alın',
        iconData: 'shield_person',
      ),
      InsuranceProduct(
        id: '2',
        name: 'Sağlık Sigortası',
        description: 'Sağlık harcamalarınız için kapsamlı koruma',
        iconData: 'health_and_safety',
      ),
      InsuranceProduct(
        id: '3',
        name: 'Araç Sigortası',
        description: 'Aracınız için tam koruma',
        iconData: 'directions_car',
      ),
    ];
  }

  List<RetirementPlan> getRetirementPlans() {
    return [
      RetirementPlan(
        id: '1',
        name: 'Bireysel Emeklilik',
        description: 'Geleceğiniz için düzenli birikim',
        minAmount: 500,
      ),
      RetirementPlan(
        id: '2',
        name: 'Kurumsal Emeklilik',
        description: 'Şirketler için özel emeklilik planları',
        minAmount: 1000,
      ),
    ];
  }
} 